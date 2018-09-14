//
//  HomeViewController.swift
//  MyTodayNews
//
//  Created by Admin on 2018/3/26.
//  Copyright © 2018年 Wellim. All rights reserved.
//

import UIKit
import SGPagingView

class HomeViewController: UIViewController {
  /// 标题和内容
    var pageTitleView : SGPageTitleView?
    var pageContenView : SGPageContentView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.keyWindow?.theme_backgroundColor = "colors.windowColor"
//        设置状态栏属性
        navigationController?.navigationBar.barStyle = .black
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.setBackgroundImage(UIImage(named: "navigation_background" + (UserDefaults.standard.bool(forKey: isNight) ? "_night" : "")), for: .default)
        
    }
    
   
}
//延展
extension HomeViewController {
    
    func setupUI()  {
    
        view.theme_backgroundColor = "colors.cellBackgroundColor"
        
    }
    
    
}
