import Foundation
import UITestRunner

class LogIn_AttemptToLogInWithAnInvalidPassword: Feat { 

    @objc func given_IAmAtTheLoginScreen() throws {}
    
    @objc func when_IInputMyEmailAddress() throws {}
    
    @objc func and_IInputMyPassword() throws {}
    
    @objc func and_ITapTheLogInButton() throws {}
    
    @objc func then_ISeeTheDashboardScreen() throws {}
    
}

