

InModuleScope PSForge {
    Describe "Test-DSCModule" {
        
        . $PSScriptRoot\PesterHelpers.ps1

        $fakeAzureCredentials = @'
[88df33b9-3d6f-400c-8710-286c92201693]
client_id = "e39eb0ee-9347-487e-a5d2-a7a49628bd29"
client_secret = "ix8xyzc7"
tenant_id = "eaecf0d8-a78a-45b6-a9b1-393398fb1e1a"
'@

        Mock getProjectRoot { "/fake-path"}
        Mock Push-Location {}
        Mock Pop-Location {}
        Mock BootstrapDSCModule {}
        Mock Invoke-ExternalCommand {}
        Mock Invoke-ExternalCommandRealtime {}
        Mock updateBundle {}
        Mock Invoke-Paket {}
        Mock Read-Host {}
        Mock Get-Content { $fakeAzureCredentials } -ParameterFilter { $Path -eq "$HOME/.azure/credentials" }
        Mock Invoke-ScriptAnalyzer {}
       
        it "Should throw an exception if the credentials file is missing" {
            Mock Test-Path { $False } -ParameterFilter { $Path -eq "$HOME/.azure/credentials" }
            { Test-DSCModule } | Should Throw "Create an azure credentials file at"
        }

        it "Should prompt the user if the subscription environment variable has not been set" {
            Mock Test-Path { $True } -ParameterFilter { $Path -eq "$HOME/.azure/credentials" }
            Mock Test-Path { $False } 
            
            Test-DSCModule

            Assert-MockCalled Read-Host -Exactly 1 -Scope It
        }

        it "Should bootstrap the module dependencies" {
            Test-DSCModule
            Assert-MockCalled BootstrapDSCModule -Exactly 1 -Scope It
        }

        it "Should update the ruby bundle" {
            Test-DSCModule
            Assert-MockCalled updateBundle -Exactly 1 -Scope It
        }

        it "Should pass the correct argument to Test Kitchen by default" {
            Test-DSCModule
            Assert-MockCalled Invoke-ExternalCommandRealtime -ParameterFilter { $Command -eq "bundle" -and  (Compare-Array $Arguments @("exec", "kitchen", "verify")) } -Scope It
        }

        it "Should pass the correct argument to Test Kitchen if different action is specified" {
            Test-DSCModule converge
            Assert-MockCalled Invoke-ExternalCommandRealtime -ParameterFilter { $Command -eq "bundle" -and  (Compare-Array $Arguments @("exec", "kitchen", "converge")) } -Scope It
        }

        it "Should throw an exception if invalid action is specified" {
            { Test-DSCModule invalid } | Should Throw 
        }

        it "Should pass the correct argument to Test Kitchen if -Debug is used" {
            Test-DSCModule -Debug
            Assert-MockCalled Invoke-ExternalCommandRealtime -ParameterFilter { $Command -eq "bundle" -and (Compare-Array $Arguments @("exec", "kitchen", "verify", "--log-level","Debug")) } -Scope It
        }

        it "Should run PSScriptAnalyzer on Windows" {
            Mock isWindows { $true }
            Test-DSCModule converge
            Assert-MockCalled Invoke-ScriptAnalyzer -ParameterFilter { $Path -eq ".\DSCResources" -and $Recurse -eq $True -and $Settings -eq "${PWD}\PSScriptAnalyzerSettings.psd1" } -Exactly 1 -Scope It
        }        
        
        it "Should not run PSScriptAnalyzer on Unix" {
            Mock isWindows { $false }
            Test-DSCModule converge
            Assert-MockCalled Invoke-ScriptAnalyzer  -Exactly 0 -Scope It
        }

        it "Should be able to override PSScriptAnalyzer with a switch " {
            $True | Should be $False
        }      

        
    }
}