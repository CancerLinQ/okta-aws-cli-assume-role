#
# Copyright 2018 Okta
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
function Install-OktaAwsCli {
    if (Test-Path $HOME\.okta\uptodate) {
        return
    }
    if (Test-Path $HOME\.okta) {
        if (Test-Path $HOME\.okta\*.jar) {
            Remove-Item $HOME\.okta\*.jar
        }
        if (Test-Path $HOME\.okta\config.properties) {
            Remove-Item $HOME\.okta\config.properties
            Test-Path = null
        }
    } else {
        New-Item -ItemType Directory -Path $HOME\.okta
    }
    Add-Content -Path $Home/.okta/config.properties -Value "
#OktaAWSCLI
OKTA_ORG=clq.okta.com
OKTA_AWS_APP_URL=https://clq.okta.com/home/amazon_aws/0oangh6wv2zucPviH296/272
OKTA_USERNAME=$env:USERNAME
"
    if (!(Test-Path $profile)) {
        New-Item -Path $profile -ItemType File -Force
    }
    $ProfileContent = Get-Content $profile
    if (!$ProfileContent -or !$ProfileContent.Contains("#OktaAWSCLI")) {
        Add-Content -Path $profile -Value '
#OktaAWSCLI
function With-Okta {
    Param([string]$Profile)
    Write-Host $args
    $OriginalOKTA_PROFILE = $env:OKTA_PROFILE
    try {
        $env:OKTA_PROFILE = $Profile
        $InternetOptions = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
        if ($InternetOptions.ProxyServer) {
            ($ProxyHost, $ProxyPort) = $InternetOptions.ProxyServer.Split(":")
        }
        if ($InternetOptions.ProxyOverride) {
            $NonProxyHosts = [System.String]::Join("|", ($InternetOptions.ProxyOverride.Replace("<local>", "").Split(";") | Where-Object {$_}))
        } else {
            $NonProxyHosts = ""
        }
        java "-Dhttp.proxyHost=$ProxyHost" "-Dhttp.proxyPort=$ProxyPort" "-Dhttps.proxyHost=$ProxyHost" "-Dhttps.proxyPort=$ProxyPort" "-Dhttp.nonProxyHosts=$NonProxyHosts" -classpath $HOME\.okta\* com.okta.tools.WithOkta @args
    } finally {
        $env:OKTA_PROFILE = $OriginalOKTA_PROFILE
    }
}
function okta-aws {
    Param([string]$Profile)
    With-Okta -Profile $Profile aws.cmd --profile $Profile @args
}
function okta-sls {
    Param([string]$Profile)
    With-Okta -Profile $Profile sls --stage $Profile @args
}
'
    }
}
Install-OktaAwsCli
Copy-Item "..\out\okta-aws-cli-1.0.4.jar" -Destination "$Home\.okta\okta-aws-cli.jar"
.$PROFILE
