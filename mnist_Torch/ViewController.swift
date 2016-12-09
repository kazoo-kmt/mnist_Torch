//
//  ViewController.swift
//  mnist_Torch
//
//  Created by Kazu Komoto on 12/8/16.
//  Copyright © 2016 mycompany. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    Bundle.main.path(forResource: "main", ofType: "lua")
    
    let torch = Torch()
    torch.initialize()
    torch.runMain("main", inFolder: "mnist_lua")
//    [self.t loadFileWithName:@"xor_model.net" inResourceFolder:@"xor_lua" andLoadMethodName:@"loadNeuralNetwork"];
//    let vm = init_torch_vm()
//    run_torch_script(vm, "/lua/main.lua")
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

