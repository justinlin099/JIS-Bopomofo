// Native COM router. No keyboard hooks, threads or services.
// Select a validated local patch only when the current Microsoft source matches.
// Unknown/updated sources, missing caches and failed patch loads use the current
// original Microsoft component instead. Nothing is loaded from DllMain.
#define UNICODE
#define _UNICODE
#include <windows.h>
#include <bcrypt.h>
#include <objbase.h>
#include <wchar.h>
#include <string.h>
typedef HRESULT (WINAPI *GETCLASS)(REFCLSID,REFIID,void**);
static HMODULE self,component;
static INIT_ONCE once=INIT_ONCE_STATIC_INIT;
static GETCLASS getClass;
static HRESULT failure=E_FAIL;
struct Known {const char *source,*patch;const wchar_t *file;};
#ifdef _WIN64
static const struct Known known[]={
 {"3ec5a3b9909d36b2b36ee06365b0678ebf03338dfc56326f8483d1341b1e829a","8e8d9def07a3c265849b9f16c4c7598a917c75a5e958b5b5daa045539d7e2179",L"ImTcCore-JIS-Table7-lab64.dll"},
 {"f476b20ee91bdf2e49b5c8bfdbc95cfa0bab7146cd52c98a65e71e6148bfd047","a10b1057218370a2c8b7f34f782560293e91282573df13c180bd6011d600e5e3",L"ImTcCore-JIS-Table7-5856-64.dll"},
 {"9c74ca43cb645413fda01f789490c1294b1573446b501d49c23bde90d2f79628","8b68c27b2b03d1982cdaa4c5866d69a04da70e6bb7516d597e2f90a3e627de03",L"ImTcCore-JIS-Table7-5794-64.dll"}
};
#else
static const struct Known known[]={
 {"65edaa2a72d21edd0c77062c08e85c9e8a4fd24330c5d3a1a71d2b574d94c51a","69000a5d61888e90c01105064ea718415ee15d91230572cfb15ce352f9b96780",L"ImTcCore-JIS-Table7-lab32.dll"},
 {"ff5d0461f872106e1fe92b808e9b3c3b140fbccbc1dd8a4b196d23cfc0ab19c8","6728cfbf861fe90ac28a36c945333fd9d8a64a64fcc6bd659e5216eaf7c33b8d",L"ImTcCore-JIS-Table7-5856-32.dll"},
 {"cbe11e33246587e9856dd8cbbfcd21007befe3ac526ec1efad791f3c6c44c4ac","9d904516fbdd0fa37a2acd84f0100d75cd5c8a7998003ff0632efb81125c59b9",L"ImTcCore-JIS-Table7-5794-32.dll"}
};
#endif
static BOOL hashFile(HANDLE file,char out[65]){
 BCRYPT_ALG_HANDLE alg=NULL;BCRYPT_HASH_HANDLE hash=NULL;
 BYTE bytes[16384],digest[32];DWORD got;BOOL ok=FALSE;
 if(BCryptOpenAlgorithmProvider(&alg,BCRYPT_SHA256_ALGORITHM,NULL,0)<0)goto end;
 if(BCryptCreateHash(alg,&hash,NULL,0,NULL,0,0)<0)goto end;
 for(;;){if(!ReadFile(file,bytes,sizeof(bytes),&got,NULL))goto end;if(!got)break;if(BCryptHashData(hash,bytes,got,0)<0)goto end;}
 if(BCryptFinishHash(hash,digest,32,0)<0)goto end;
 for(int i=0;i<32;i++){out[2*i]="0123456789abcdef"[digest[i]>>4];out[2*i+1]="0123456789abcdef"[digest[i]&15];}out[64]=0;ok=TRUE;
end:if(hash)BCryptDestroyHash(hash);if(alg)BCryptCloseAlgorithmProvider(alg,0);return ok;
}
static BOOL load(const wchar_t *path){
 HMODULE mod=LoadLibraryExW(path,NULL,LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR|LOAD_LIBRARY_SEARCH_SYSTEM32);
 if(!mod){failure=HRESULT_FROM_WIN32(GetLastError());return FALSE;}
 GETCLASS factory=(GETCLASS)GetProcAddress(mod,"DllGetClassObject");
 if(!factory){failure=HRESULT_FROM_WIN32(ERROR_PROC_NOT_FOUND);FreeLibrary(mod);return FALSE;}
 component=mod;getClass=factory;return TRUE;
}
static BOOL CALLBACK initialize(PINIT_ONCE ignored,void *parameter,void **context){
 wchar_t original[MAX_PATH],cache[MAX_PATH];
 UINT size=GetSystemDirectoryW(original,MAX_PATH);
 if(!size||size>=MAX_PATH-32){failure=HRESULT_FROM_WIN32(ERROR_INSUFFICIENT_BUFFER);return TRUE;}
 wcscat(original,L"\\IME\\IMETC\\IMTCCORE.DLL");
 char sourceHash[65]={0};
 HANDLE file=CreateFileW(original,GENERIC_READ,FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL);
 BOOL valid=file!=INVALID_HANDLE_VALUE&&hashFile(file,sourceHash);if(file!=INVALID_HANDLE_VALUE)CloseHandle(file);
 DWORD length=GetModuleFileNameW(self,cache,MAX_PATH);
 if(valid&&length&&length<MAX_PATH){
  wchar_t *end=wcsrchr(cache,L'\\');if(end){end[1]=0;size_t prefix=wcslen(cache);
   for(size_t i=0;i<sizeof(known)/sizeof(*known);i++)if(!strcmp(sourceHash,known[i].source)&&prefix+wcslen(known[i].file)<MAX_PATH){
    wcscpy(cache+prefix,known[i].file);char patchHash[65]={0};
    // Deny cache replacement between validation and module loading.
    HANDLE patch=CreateFileW(cache,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL);
    BOOL loaded=FALSE;if(patch!=INVALID_HANDLE_VALUE){if(hashFile(patch,patchHash)&&!strcmp(patchHash,known[i].patch))loaded=load(cache);CloseHandle(patch);}
    if(loaded)return TRUE;break;
   }
  }
 }
 load(original);return TRUE;
}
HRESULT WINAPI DllGetClassObject(REFCLSID clsid,REFIID iid,void **object){
 if(!object)return E_POINTER;*object=NULL;
 if(!InitOnceExecuteOnce(&once,initialize,NULL,NULL))return HRESULT_FROM_WIN32(GetLastError());
 return getClass?getClass(clsid,iid,object):failure;
}
// The forwarded objects are owned by the selected Microsoft module. Keep both
// modules alive for this process, avoiding unsafe object-lifetime guesses.
HRESULT WINAPI DllCanUnloadNow(void){return S_FALSE;}
BOOL WINAPI DllMain(HINSTANCE instance,DWORD reason,LPVOID reserved){if(reason==DLL_PROCESS_ATTACH)self=instance;return TRUE;}
