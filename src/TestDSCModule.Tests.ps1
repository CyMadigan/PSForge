

InModuleScope PSForge {
    Describe "Test-DSCModule" {
        
        . $PSScriptRoot\PesterHelpers.ps1

        Mock getProjectRoot { "/fake-path"}
        Mock Push-Location {}
        Mock Pop-Location {}
        Mock BootstrapDSCModule {}
        Mock Invoke-ExternalCommand {}
        Mock updateBundle {}
        Mock Invoke-Paket {}
        Mock Read-Host {}
       
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
            Assert-MockCalled Invoke-ExternalCommand -ParameterFilter { $Command -eq "bundle" -and (Compare-Array $Arguments @("exec", "kitchen", "verify")) } -Scope It
        }

        it "Should pass the correct argument to Test Kitchen if different action is specified" {
            Test-DSCModule converge
            Assert-MockCalled Invoke-ExternalCommand -ParameterFilter { $Command -eq "bundle" -and (Compare-Array $Arguments @("exec", "kitchen", "converge")) } -Scope It
        }

        it "Should throw an exception if invalid action is specified" {
            { Test-DSCModule invalid } | Should Throw 
        }

        it "Should pass the correct argument to Test Kitchen if -Debug is used" {
            Test-DSCModule -Debug
            Assert-MockCalled Invoke-ExternalCommand -ParameterFilter { $Command -eq "bundle" -and (Compare-Array $Arguments @("exec", "kitchen", "verify", "--log-level","Debug")) } -Scope It
        }
    }
}