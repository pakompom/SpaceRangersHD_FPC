"""Build invalidation checks using temporary sources and a simulated compiler.

Run with: python3 -m unittest discover -s tests
No installed compiler, game assets, or build cache is used.
"""

import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import build_support as native
import compiler
import pascal
from targets import BuildConfig


class BuildFixture(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="srhd build ")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.work = self.root / "work"
        self.work.mkdir()
        self.sources = self.root / "sources"
        self.sources.mkdir()
        self.source = self.sources / "main.pas"
        self.source.write_text("program main; begin end.")
        self.unit = self.work / "main.ppu"
        self.artifact = self.work / "Rangers"
        self.compiler = self.root / "fpc"
        self.clang = self.root / "clang"
        for tool in (self.compiler, self.clang):
            tool.write_text("simulated compiler")
            tool.chmod(0o755)
        environment = patch.dict(os.environ, {"PATH": str(self.root)})
        environment.start()
        self.addCleanup(environment.stop)

    @staticmethod
    def edit(path, *, offset_ns=0):
        """Change content while controlling the timestamp seen by FPC."""
        before = path.stat()
        path.write_text(path.read_text().replace("a", "b", 1))
        os.utime(path, ns=(before.st_atime_ns, before.st_mtime_ns + offset_ns))


class PascalBuildTests(BuildFixture):
    def setUp(self):
        super().setUp()
        self.command = [self.compiler, f"-Fu{self.sources}", f"-FU{self.work}", self.source]
        self.dependencies = ()
        self.calls = []
        self.units_present = []

        def compile_step(work, name, command):
            self.calls.append(command)
            self.units_present.append(self.unit.exists())
            self.unit.write_text("compiled unit")
            self.artifact.write_text("compiled program")

        runner = patch.object(pascal, "run_step", side_effect=compile_step)
        self.runner = runner.start()
        self.addCleanup(runner.stop)

    def build(self, rebuild=False):
        return pascal.compile_pascal(
            self.work, self.command, rebuild, self.artifact, self.dependencies
        )

    def assert_full_rebuild(self):
        self.assertTrue(self.build())
        self.assertIn("-B", self.calls[-1])
        self.assertFalse(self.build(), "the rebuilt outputs must be cached")

    def test_first_build_then_unchanged(self):
        self.assert_full_rebuild()
        self.assertEqual(len(self.calls), 1)

    def test_ordinary_edit_uses_fpc_incremental_compilation(self):
        self.build()
        self.edit(self.source, offset_ns=2_000_000_000)
        self.assertTrue(self.build())
        self.assertNotIn("-B", self.calls[-1])
        self.assertFalse(self.build())

    def test_preserved_mtime_edit_forces_rebuild(self):
        self.build()
        self.edit(self.source)
        self.assert_full_rebuild()

    def test_two_edits_in_same_second_force_rebuild(self):
        second = self.source.stat().st_mtime_ns // 1_000_000_000 * 1_000_000_000
        os.utime(self.source, ns=(second, second + 100))
        self.build()
        self.edit(self.source, offset_ns=100)
        self.assert_full_rebuild()

    def test_added_and_removed_input_force_rebuild(self):
        self.build()
        include = self.sources / "options.inc"
        include.write_text("{$define EXAMPLE}")
        self.assert_full_rebuild()
        include.unlink()
        self.assert_full_rebuild()

    def test_missing_and_replaced_unit_force_rebuild(self):
        self.build()
        self.unit.unlink()
        self.assert_full_rebuild()
        self.edit(self.unit)
        self.assert_full_rebuild()

    def test_missing_binary_is_recreated(self):
        self.build()
        self.artifact.unlink()
        self.assertTrue(self.build())
        self.assertTrue(self.artifact.is_file())

    def test_changed_link_dependency_does_not_recompile_all_units(self):
        library = self.root / "libokgf.a"
        library.write_text("native library")
        self.dependencies = (library,)
        self.build()
        self.edit(library)
        self.assertTrue(self.build())
        self.assertNotIn("-B", self.calls[-1])

    def test_flag_change_forces_rebuild(self):
        self.build()
        self.command.insert(1, "-O4")
        self.assert_full_rebuild()

    def test_relevant_environment_change_forces_rebuild(self):
        self.build()
        with patch.dict(os.environ, {"SDKROOT": "/different/sdk"}):
            self.assert_full_rebuild()

    def test_compiler_replaced_with_older_mtime_forces_rebuild(self):
        self.build()
        self.edit(self.compiler, offset_ns=-10_000_000_000)
        self.assert_full_rebuild()

    def test_clang_replaced_with_preserved_mtime_forces_rebuild(self):
        self.build()
        self.edit(self.clang)
        self.assert_full_rebuild()

    def test_explicit_rebuild_forces_rebuild(self):
        self.build()
        self.assertTrue(self.build(rebuild=True))
        self.assertIn("-B", self.calls[-1])

    def test_released_package_discards_units_after_input_change(self):
        self.command.insert(1, "-Ur")
        self.build()
        self.edit(self.source, offset_ns=2_000_000_000)
        self.assert_full_rebuild()
        self.assertFalse(self.units_present[-1])

    def test_failed_build_invalidates_previous_success(self):
        self.build()
        self.command.insert(1, "-O4")
        with (
            patch.object(pascal, "run_step", side_effect=RuntimeError("compile failed")),
            self.assertRaisesRegex(RuntimeError, "compile failed"),
        ):
            self.build()
        self.command.remove("-O4")
        self.assert_full_rebuild()


class NativeBuildTests(BuildFixture):
    def test_depfile_tracks_header_changes(self):
        header = self.sources / "header with spaces.h"
        header.write_text("a declaration")
        obj = self.work / "native.o"
        command = [self.clang, "-c", self.source, "-o", obj]

        def compile_step(work, name, command):
            obj.write_text("object")
            depfile = Path(command[command.index("-MF") + 1])
            escaped = str(header).replace(" ", "\\ ")
            depfile.write_text(f"native.o: {escaped}\n")

        with patch.object(native, "run_step", side_effect=compile_step) as runner:
            native.compile_native(self.work, command, False)
            native.compile_native(self.work, command, False)
            self.assertEqual(runner.call_count, 1)
            self.edit(header)
            native.compile_native(self.work, command, False)
            self.assertEqual(runner.call_count, 2)
            (self.work / "native.d").write_text("malformed dependency file")
            native.compile_native(self.work, command, False)
            self.assertEqual(runner.call_count, 3)

    def test_link_requires_all_outputs_and_tracks_inputs(self):
        wasm = self.work / "game.wasm"
        loader = self.work / "game.js"
        command = [self.clang, self.source, "-o", loader]

        def link_step(*args):
            wasm.write_text("wasm")
            loader.write_text("javascript")

        def link():
            native.link_native(self.work, command, [self.source], [loader, wasm], False)

        with patch.object(native, "run_step", side_effect=link_step) as runner:
            link()
            link()
            self.assertEqual(runner.call_count, 1)
            self.edit(self.source)
            link()
            self.assertEqual(runner.call_count, 2)
            wasm.unlink()
            link()
            self.assertEqual(runner.call_count, 3)

    def test_cmake_compiler_replacement_requires_clean_build(self):
        directory = self.work / "native"
        directory.mkdir()
        command = [self.clang, "configure"]

        def configure_step(*args):
            (directory / "CMakeCache.txt").write_text(f"CMAKE_C_COMPILER:FILEPATH={self.clang}\n")

        with (
            patch.object(native, "ROOT", self.root),
            patch.object(native, "run_step", side_effect=configure_step) as runner,
        ):
            self.assertFalse(native.configure_native(self.work, directory, command))
            self.assertFalse(native.configure_native(self.work, directory, command))
            self.assertEqual(runner.call_count, 1)
            self.edit(self.clang, offset_ns=-10_000_000_000)
            self.assertTrue(native.configure_native(self.work, directory, command))
            self.assertEqual(runner.call_count, 2)

    def test_bootstrap_revision_tracks_tool_replacement(self):
        command = [self.compiler, "compiler_cycle"]
        before = compiler.recipe_revision("source revision", command, (self.compiler,))
        self.edit(self.compiler, offset_ns=-10_000_000_000)
        after = compiler.recipe_revision("source revision", command, (self.compiler,))
        self.assertNotEqual(before, after)

    def test_failed_configure_retries_and_requires_clean_build(self):
        directory = self.work / "native"
        directory.mkdir()
        (directory / "CMakeCache.txt").write_text(f"CMAKE_C_COMPILER:FILEPATH={self.clang}\n")
        command = [self.clang, "configure"]
        with patch.object(native, "ROOT", self.root):
            with (
                patch.object(native, "run_step", side_effect=RuntimeError("configure failed")),
                self.assertRaisesRegex(RuntimeError, "configure failed"),
            ):
                native.configure_native(self.work, directory, command)
            with patch.object(native, "run_step") as runner:
                self.assertTrue(native.configure_native(self.work, directory, command))
                runner.assert_called_once()


class StampTests(BuildFixture):
    def test_failed_post_build_signature_does_not_cache_success(self):
        stamp = native.BuildStamp(self.work / "build.stamp")
        with stamp.recording("previous"):
            self.artifact.write_text("previous output")

        def signature():
            raise ValueError("invalid depfile")

        with self.assertRaisesRegex(ValueError, "invalid depfile"), stamp.recording(signature):
            self.artifact.write_text("new output")
        self.assertFalse(native.BuildStamp(stamp.path).matches("previous", self.artifact))


class ConfigurationTests(unittest.TestCase):
    def test_existing_output_layout_for_all_profiles(self):
        root = Path("/project")
        directories = {
            "macos": root / ".local",
            "linux": root / ".local/linux-aarch64",
            "wasm": root / ".local/wasm",
        }
        with patch("targets.host_cpu", return_value="aarch64"):
            for target, directory in directories.items():
                for release in (False, True):
                    for lto in (False, True):
                        with self.subTest(target=target, release=release, lto=lto):
                            config = BuildConfig(target, release, lto, root)
                            profile = ("release" if release else "debug") + ("-lto" if lto else "")
                            self.assertEqual(config.work, directory / profile)
                            if target == "macos":
                                self.assertEqual(
                                    config.artifact, config.work / "Space Rangers HD.app"
                                )
                                self.assertEqual(
                                    config.binary_directory, config.artifact / "Contents/MacOS"
                                )
                            else:
                                self.assertEqual(config.binary_directory, config.work / "bin")
                                name = "index.html" if target == "wasm" else "Rangers"
                                self.assertEqual(config.artifact, config.binary_directory / name)

    def test_unknown_target_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "Unsupported target"):
            BuildConfig("unknown")


if __name__ == "__main__":
    unittest.main()
