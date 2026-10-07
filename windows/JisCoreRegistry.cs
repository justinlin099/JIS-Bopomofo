// One protected component key for this component; no ownership/ACL changes.
using System;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
using Microsoft.Win32;
using Microsoft.Win32.SafeHandles;
public static class JisCoreRegistryV2 {
 const string Key=@"SOFTWARE\Classes\CLSID\{25ecf786-a925-4706-a269-eef5ad6899db}\InProcServer32";
 [StructLayout(LayoutKind.Sequential,Pack=1)] struct TP {public uint Count;public long Luid;public uint Attr;}
 [DllImport("advapi32",SetLastError=true)] static extern bool OpenProcessToken(IntPtr p,uint access,out IntPtr t);
 [DllImport("advapi32",CharSet=CharSet.Unicode,SetLastError=true)] static extern bool LookupPrivilegeValue(string sys,string n,out long luid);
 [DllImport("advapi32",SetLastError=true)] static extern bool AdjustTokenPrivileges(IntPtr t,bool all,ref TP n,int size,out TP prev,out int needed);
 [DllImport("kernel32")] static extern IntPtr GetCurrentProcess();
 [DllImport("kernel32")] static extern bool CloseHandle(IntPtr h);
 [DllImport("advapi32",CharSet=CharSet.Unicode)] static extern int RegCreateKeyEx(IntPtr root,string sub,uint reserved,string cls,uint options,uint access,IntPtr security,out SafeRegistryHandle h,out uint disposition);
 public static void Set(string expected,RegistryValueKind expectedKind,string value,RegistryValueKind valueKind) {
  if(!Environment.Is64BitProcess)throw new InvalidOperationException("64-bit process only");
  string original=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System),@"IME\IMETC\IMTCCORE.DLL");
  string folder=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),"Fujitsu-JIS-Core")+Path.DirectorySeparatorChar;
  if((expectedKind!=RegistryValueKind.String && expectedKind!=RegistryValueKind.ExpandString) || (valueKind!=RegistryValueKind.String && valueKind!=RegistryValueKind.ExpandString))throw new InvalidOperationException("Only String and ExpandString are supported");
  string resolved=Path.GetFullPath(valueKind==RegistryValueKind.ExpandString?Environment.ExpandEnvironmentVariables(value):value);
  if(!String.Equals(resolved,original,StringComparison.OrdinalIgnoreCase) && !resolved.StartsWith(folder,StringComparison.OrdinalIgnoreCase))throw new InvalidOperationException("Target must be original core or private installation folder");
  using(var existing=Registry.LocalMachine.OpenSubKey(Key)){
   if(existing==null || existing.GetValueKind("")!=expectedKind || !String.Equals((string)existing.GetValue("",null,RegistryValueOptions.DoNotExpandEnvironmentNames),expected,StringComparison.Ordinal))throw new InvalidOperationException("Unexpected current component value");
  }
  IntPtr token;if(!OpenProcessToken(GetCurrentProcess(),0x28,out token))throw new Win32Exception();
  TP[] previous=new TP[2];int count=0;
  try {
   foreach(string n in new[]{"SeBackupPrivilege","SeRestorePrivilege"}){
    long luid;if(!LookupPrivilegeValue(null,n,out luid))throw new Win32Exception();
    TP next=new TP{Count=1,Luid=luid,Attr=2};int needed;
    if(!AdjustTokenPrivileges(token,false,ref next,Marshal.SizeOf(typeof(TP)),out previous[count],out needed)||Marshal.GetLastWin32Error()!=0)throw new Win32Exception();
    count++;
   }
   SafeRegistryHandle handle;uint disposition;
   int error=RegCreateKeyEx(new IntPtr(unchecked((int)0x80000002)),Key,0,null,4,0,IntPtr.Zero,out handle,out disposition);
   if(error!=0)throw new Win32Exception(error);
   using(handle){
    if(disposition!=2)throw new InvalidOperationException("Existing key required");
    using(var key=RegistryKey.FromHandle(handle)){
     if(key.GetValueKind("")!=expectedKind || !String.Equals((string)key.GetValue("",null,RegistryValueOptions.DoNotExpandEnvironmentNames),expected,StringComparison.Ordinal))throw new InvalidOperationException("Component value changed during operation");
     key.SetValue("",value,valueKind);
    }
   }
  }finally{
   while(count>0){count--;TP ignored;int size;AdjustTokenPrivileges(token,false,ref previous[count],0,out ignored,out size);}
   CloseHandle(token);
  }
 }
}

