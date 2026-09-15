{$EXCESSPRECISION OFF}
unit SE_Garbage;
{$R-}
{$Q-}
{$B-}
{$A8}
interface
var
  PreviousVirtualUsageMB: Int64 = 0;
  PreviousPhysicalUsageMB: Int64 = 0;
  CheckingMemoryUsage: Boolean = False;
  LowMemoryWarningShown: Boolean = False;
procedure CheckMemoryUsage;
implementation
uses
  Math,
  Windows,
  GR_Main,
  SysUtils,
  aGalaxy;

procedure CheckMemoryUsage;
var
  Usage: Int64;
  Changed: Boolean;
  Reserved: array[0..6] of Byte; // Native local storage between the flag and the status record.
  Status: TMemoryStatusEx;
  procedure ShowLowMemoryWarning(
      TextKey: WideString
  ); // @addr $86E0F0 @ida "void __usercall $name(unsigned __int16 *TextKey@<eax>, void *ParentFrame@<^0>);" @note "Nested in CheckMemoryUsage; unused caller-popped static link."
  begin
    if (not LowMemoryWarningShown) and (Galaxy <> nil) then
    begin
      LowMemoryWarningShown := True;
      Galaxy.ShowLocalizedWarning(TextKey);
    end;
  end;
begin
  if not CheckingMemoryUsage then
  begin
    CheckingMemoryUsage := True;
    Changed := False;
    Status.Length := SizeOf(Status);
    GlobalMemoryStatusEx(Status);
    Usage := (Status.TotalVirtual - Status.AvailVirtual) shr 20;
    if (Usage > 512) and (Abs(Usage - PreviousVirtualUsageMB) > 256) then
    begin
      if PreviousVirtualUsageMB <> 0 then
      begin
        Changed := True;
        if Usage > PreviousVirtualUsageMB then
          AppendLogLineThreadSafe('Virtual memory usage is increasing (' + IntToStr(Usage) + ' MB)')
        else
          AppendLogLineThreadSafe(
              'Virtual memory usage is decreasing (' + IntToStr(Usage) + ' MB)'
          );
      end;
      PreviousVirtualUsageMB := Usage;
    end;
    if Status.AvailVirtual shr 20 < 100 then
      ShowLowMemoryWarning('Warning.LowVirtualMemory');
    Usage := (Status.TotalPhys - Status.AvailPhys) shr 20;
    if (Usage > 512) and (Abs(Usage - PreviousPhysicalUsageMB) > 256) then
    begin
      if PreviousPhysicalUsageMB <> 0 then
      begin
        Changed := True;
        if Usage > PreviousPhysicalUsageMB then
          AppendLogLineThreadSafe(
              'Physical memory usage is increasing (' + IntToStr(Usage) + ' MB)'
          )
        else
          AppendLogLineThreadSafe(
              'Physical memory usage is decreasing (' + IntToStr(Usage) + ' MB)'
          );
      end;
      PreviousPhysicalUsageMB := Usage;
    end;
    if Status.AvailPhys shr 20 < 100 then
      ShowLowMemoryWarning('Warning.LowPhysicalMemory');
    if Changed then
      LogMemoryUsage;
    CheckingMemoryUsage := False;
  end;
end;

end.
