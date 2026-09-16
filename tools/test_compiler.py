"""Fast checks for runtime cache isolation and recovery; no compiler invocation."""

import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import compiler


class RuntimeCacheTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        self.work = root / "work"
        self.source = self.work / "source"
        vendor = root / "vendor"
        for base in (self.source, vendor):
            (base / "compiler").mkdir(parents=True)
            (base / "packages").mkdir()
            (base / "rtl").mkdir()
        (vendor / "compiler/pp.pas").touch()
        (self.source / "compiler/ppca64").touch()
        (self.source / "rtl/source.inc").write_text("runtime source")
        (self.work / "compiler.stamp").write_text("revision")
        for name, value in (("WORK", self.work), ("SOURCE", self.source), ("VENDOR", vendor)):
            self.enterContext(patch.object(compiler, name, value))
        self.enterContext(patch.object(compiler, "source_revision", return_value="revision"))
        self.enterContext(patch.object(compiler.subprocess, "check_output", return_value="/sdk\n"))
        self.calls = []
        self.fail = False

    def build_runtime(self, work, name, command):
        self.assertEqual(name, "runtime")
        self.calls.append(list(map(str, command)))
        units = work / "src/rtl/units/aarch64-darwin"
        units.mkdir(parents=True, exist_ok=True)
        (units / "classes.ppu").write_text("partial" if self.fail else "complete")
        if self.fail:
            raise RuntimeError("simulated compiler failure")

    def test_switching_profiles_reuses_separate_optimized_runtimes(self):
        host, normal = compiler.prepare_compiler("macos", self.build_runtime)
        lto_host, lto = compiler.prepare_compiler("macos", self.build_runtime, lto=True)
        self.assertEqual(host, lto_host)
        self.assertNotEqual(normal, lto)
        self.assertNotIn("-Clflto", normal)
        self.assertIn("-Clflto", lto)
        self.assertEqual(len(self.calls), 2)
        for command in self.calls:
            self.assertIn("-dCLASSESINLINE", next(x for x in command if x.startswith("OPT=")))
        self.assertNotIn("-Clflto", self.calls[0][-1])
        self.assertIn("-Clflto", self.calls[1][-1])
        compiler.prepare_compiler("macos", self.build_runtime)
        compiler.prepare_compiler("macos", self.build_runtime, lto=True)
        self.assertEqual(len(self.calls), 2)
        self.assertFalse((self.source / "rtl/units").exists())

    def test_failed_runtime_is_not_reused(self):
        self.fail = True
        with self.assertRaisesRegex(RuntimeError, "simulated"):
            compiler.prepare_compiler("macos", self.build_runtime, lto=True)
        runtime = self.work / "runtime/aarch64-darwin-lto"
        self.assertFalse((runtime / "runtime.stamp").exists())
        (runtime / "src/rtl/stale.o").touch()
        self.fail = False
        compiler.prepare_compiler("macos", self.build_runtime, lto=True)
        self.assertTrue((runtime / "runtime.stamp").exists())
        self.assertFalse((runtime / "src/rtl/stale.o").exists())

    def test_android_lto_is_rejected_before_bootstrap(self):
        with self.assertRaisesRegex(ValueError, "macOS"):
            compiler.prepare_compiler("android", self.build_runtime, lto=True)
        self.assertFalse(self.calls)


if __name__ == "__main__":
    unittest.main()
