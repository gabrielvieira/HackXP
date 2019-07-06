//
//  ViewController.swift
//  HackXP
//
//  Created by Gabriel vieira on 7/6/19.
//  Copyright © 2019 Gabriel vieira. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func moneyDidTap(_ sender: Any) {
        
    }
    
    @IBAction func planeDidTap(_ sender: Any) {
        
        let storyBoard = UIStoryboard(name: "MoneyAirplane", bundle: nil)
        let viewController = storyBoard.instantiateViewController(withIdentifier: "MoneyAirplane")
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    @IBAction func faceDidTap(_ sender: Any) {
        
        let storyBoard = UIStoryboard(name: "ARFaceSimple", bundle: nil)
        let viewController = storyBoard.instantiateViewController(withIdentifier: "ARFaceSimpleView")
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}
