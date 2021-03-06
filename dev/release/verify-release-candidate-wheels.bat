@rem Licensed to the Apache Software Foundation (ASF) under one
@rem or more contributor license agreements.  See the NOTICE file
@rem distributed with this work for additional information
@rem regarding copyright ownership.  The ASF licenses this file
@rem to you under the Apache License, Version 2.0 (the
@rem "License"); you may not use this file except in compliance
@rem with the License.  You may obtain a copy of the License at
@rem
@rem   http://www.apache.org/licenses/LICENSE-2.0
@rem
@rem Unless required by applicable law or agreed to in writing,
@rem software distributed under the License is distributed on an
@rem "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
@rem KIND, either express or implied.  See the License for the
@rem specific language governing permissions and limitations
@rem under the License.

@rem This script downloads and installs all Windows wheels for a release
@rem candidate into temporary conda environments and makes sure that imports
@rem work

@rem To run the script:
@rem verify-release-candidate-wheels.bat VERSION RC_NUM

@echo on

set _CURRENT_DIR=%CD%
set _VERIFICATION_DIR=C:\tmp\arrow-verify-release-wheels

if not exist "C:\tmp\" mkdir C:\tmp
if exist %_VERIFICATION_DIR% rd %_VERIFICATION_DIR% /s /q
if not exist %_VERIFICATION_DIR% mkdir %_VERIFICATION_DIR%

cd %_VERIFICATION_DIR%

CALL :verify_wheel 3.5 %1 %2 m
if errorlevel 1 GOTO error

CALL :verify_wheel 3.6 %1 %2 m
if errorlevel 1 GOTO error

CALL :verify_wheel 3.7 %1 %2 m
if errorlevel 1 GOTO error

CALL :verify_wheel 3.8 %1 %2
if errorlevel 1 GOTO error

:done
cd %_CURRENT_DIR%

EXIT /B %ERRORLEVEL%

:error
call deactivate
cd %_CURRENT_DIR%

EXIT /B 1

@rem a batch function to verify a single wheel
:verify_wheel

set PY_VERSION=%1
set ARROW_VERSION=%2
set RC_NUMBER=%3
set ABI_TAG=%4
set PY_VERSION_NO_PERIOD=%PY_VERSION:.=%

set CONDA_ENV_PATH=%_VERIFICATION_DIR%\_verify-wheel-%PY_VERSION%
call conda create -p %CONDA_ENV_PATH% ^
    --no-shortcuts -f -q -y python=%PY_VERSION% ^
    || EXIT /B 1
call activate %CONDA_ENV_PATH%

set WHEEL_FILENAME=pyarrow-%ARROW_VERSION%-cp%PY_VERSION_NO_PERIOD%-cp%PY_VERSION_NO_PERIOD%%ABI_TAG%-win_amd64.whl

@rem Requires GNU Wget for Windows
wget --no-check-certificate -O %WHEEL_FILENAME% https://bintray.com/apache/arrow/download_file?file_path=python-rc%%2F%ARROW_VERSION%-rc%RC_NUMBER%%%2F%WHEEL_FILENAME% || EXIT /B 1

pip install %WHEEL_FILENAME% || EXIT /B 1
python -c "import pyarrow" || EXIT /B 1
python -c "import pyarrow.parquet" || EXIT /B 1

if "%PY_VERSION%"=="3.5" GOTO done

:python36_and_higher_checks

python -c "import pyarrow.flight" || EXIT /B 1
python -c "import pyarrow.gandiva" || EXIT /B 1
python -c "import pyarrow.dataset" || EXIT /B 1

:done

call deactivate

EXIT /B 0
