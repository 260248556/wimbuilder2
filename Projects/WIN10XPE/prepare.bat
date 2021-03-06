if "x%~1"=="x" goto :EOF

pushd "%~dp0"
call %1
goto :DONE

:BEFORE_WIM_MOUNT
rem ===================================
rem set Enviroment
rem BUILD_NUMBER
for /f "tokens=3 delims=." %%v in ("%WB_PE_VER%") do set VER[3]=%%v
set VER[4]=%WB_PE_BUILD%
set VER[3.4]=%VER[3]%.%VER[4]%
rem ===================================
rem SYSTEM_PATH
rem set X=%WB_X_DRIVE%
set "X_PF=%X%\Program Files"
set X_WIN=%X%\Windows
set X_SYS=%X_WIN%\System32
set X_WOW64=%X_WIN%\SysWOW64
set X_Desktop=%X%\Users\Default\Desktop
set "_CUSTOMFILES_=%WB_PROJECT_PATH%\_CustomFiles_"

set "WB_USER_PROJECT_PATH=%WB_ROOT%\AppData\Projects\%WB_PROJECT%"
set "_USER_CUSTOMFILES_=%WB_USER_PROJECT_PATH%\_CustomFiles_"

call "%WB_PROJECT_PATH%\shared\InitLoader.bat"

call V2X -init
call App init _Cache_

rem call _Prepare_.bat before mounting
if exist "%_USER_CUSTOMFILES_%\_Prepare_.bat" (
    pushd "%_USER_CUSTOMFILES_%\"
    call _Prepare_.bat :BEFORE_WIM_MOUNT
    popd
)

rem ===================================
rem update options

call CheckPatch "00-Configures\x-Account"
if %errorlevel% EQU 0 (
    set opt[account.admin_enabled]=false
)

call CheckPatch "01-Components\02-Network"
set opt[support.network]=%HasPatch%
if "%opt[support.network]%"=="false" (
    set opt[network.function_discovery]=false
)

if "x%opt[account.admin_enabled]%"=="xtrue" (
    set opt[support.admin]=true
)
if "x%opt[component.netfx]%"=="xtrue" (
    set opt[build.registry.software]=full
)

call CheckPatch "01-Components\Devices and Printers"
if "x%HasPatch%_%opt[component.printer]%"=="xtrue_true" (
    set opt[build.registry.software]=full
    set opt[patch.drvinst]=true
)

if "x%opt[build.registry.system]%"=="xtrue" (
    set opt[build.registry.system]=merge
)

rem ===================================
rem reduce the wim file before mounting it
cd /d za-Slim
call SlimWim.bat
rem ===================================
goto :EOF

:BEFORE_HIVE_LOAD

rem call prepare.bat before hive load
if exist "%_USER_CUSTOMFILES_%\_Prepare_.bat" (
    pushd "%_USER_CUSTOMFILES_%\"
    call _Prepare_.bat :BEFORE_HIVE_LOAD
    popd
)

if "x%opt[build.registry.software]%"=="xfull" (
    call AddFiles \Windows\System32\config\SOFTWARE
    set REGCOPY_SKIP_SOFTWARE=1
)

goto :EOF

:DONE
popd
