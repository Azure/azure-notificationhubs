//
//  Copyright © 2018 Microsoft All rights reserved.
//  Licensed under the Apache License (2.0).
//

#import "ViewController.h"
#import "Constants.h"
#import "AppDelegate.h"

@interface ViewController ()

@end

@implementation ViewController

////////////////////////////////////////////////////////////////////////////////
//
// UIViewController methods
//
////////////////////////////////////////////////////////////////////////////////

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    // Simple method to dismiss keyboard when user taps outside of the UITextField.
    [self.view endEditing:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Load raw tags text from storage and initialize the text field
    self.tagsTextField.text = [[NSUserDefaults standardUserDefaults] valueForKey:NHUserDefaultTags];
}

////////////////////////////////////////////////////////////////////////////////
//
// Actions
//
////////////////////////////////////////////////////////////////////////////////

- (IBAction)handleRegister:(id)sender {
    // Save raw tags text in storage
    [[NSUserDefaults standardUserDefaults] setValue:self.tagsTextField.text forKey:NHUserDefaultTags];

    //
    // Delegate processing the register action to the app delegate.
    //
    [[[UIApplication sharedApplication] delegate] performSelector:@selector(handleRegister)];
}

- (IBAction)handleUnregister:(id)sender {
    //
    // Delegate processing the unregister action to the app delegate.
    //
    [[[UIApplication sharedApplication] delegate] performSelector:@selector(handleUnregister)];
}

@end
