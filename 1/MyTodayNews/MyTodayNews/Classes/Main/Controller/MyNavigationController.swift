//
//  MyNavigationController.swift
//  MyTodayNews
//
//  Created by Admin on 2018/3/26.
//  Copyright © 2018年 Wellim. All rights reserved.
//

import UIKit

class MyNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let navigationBar = UINavigationBar.appearance()
        navigationBar.theme_tintColor = "colors.black"
       
        
        navigationBar.setBackgroundImage(UIImage(named: "navigation_background" + (UserDefaults.standard.bool(forKey: isNight) ? "_night" : "")), for: .default)
        
        
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        
        if viewControllers.count > 0 {
            viewController.hidesBottomBarWhenPushed = true;
            
            viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "lefterbackicon_titlebar_24x24_"), style: .plain, target: self, action: #selector(navigationBack))
           
        }
        // 所有设置搞定后, 再push控制器
        super .pushViewController(viewController, animated: true)
    }
    /// 返回上一控制器
    @objc private func navigationBack() {
        popViewController(animated: true)
    }
}
