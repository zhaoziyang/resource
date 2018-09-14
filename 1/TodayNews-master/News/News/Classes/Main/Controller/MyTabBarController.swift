//
//  MyTabBarController.swift
//  MyTodayNews
//
//  Created by Admin on 2018/3/26.
//  Copyright © 2018年 Wellim. All rights reserved.
//

import UIKit

class MyTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let tabbar = UITabBar.appearance()
        tabbar.theme_tintColor = "colors.tabbarTintColor"
        tabbar.theme_barTintColor = "colors.cellBackgroundColor"
       
        //添加子控制器
        addChildViewControllers()
        //监听切换日夜模式
        NotificationCenter.default.addObserver(self, selector: #selector(receiveDayOrNightButtonClicked), name: NSNotification.Name(rawValue:"dayOrNightButtonClicked"), object: nil)
        
    }

    @objc func receiveDayOrNightButtonClicked(noticfcation : NSNotification) {
        let selected = noticfcation.object as! Bool
        if selected {
            for childController in childViewControllers{
                switch childController.title! {

                case "首页":
                    setNightChildContriller(controller: childController, imageName: "home")
                case "西瓜视频" : setNightChildContriller(controller: childController, imageName: "video")
                case "小视频" : setNightChildContriller(controller: childController, imageName: "huoshan")
                case "微头条" : setNightChildContriller(controller: childController, imageName: "weitoutiao")
                case "" : setNightChildContriller(controller: childController, imageName: "redpackage")
                default:
                    break

                }
            }
        
        }else{
            
            for childController in childViewControllers{
                switch childController.title! {
                    
                case "首页":
                    setDayChildController(controller: childController, imageName: "home")
                case "西瓜视频" : setDayChildController(controller: childController, imageName: "video")
                case "小视频" : setDayChildController(controller: childController, imageName: "huoshan")
                case "微头条" : setDayChildController(controller: childController, imageName: "weitoutiao")
                case "" : setDayChildController(controller: childController, imageName: "redpackage")
                default:
                    break
                    
                }
            }
        }
        
    }
    func addChildViewControllers(){
        setChildViewController(childController: HomeViewController(), title: "首页", imageName: "home")
        setChildViewController(childController: VideoViewController(), title: "西瓜视频", imageName: "video")
        setChildViewController(childController: RedPackageViewController(), title: "", imageName: "redpackage")
        setChildViewController(childController: WeitoutiaoViewController(), title: "微头条", imageName: "weitoutiao")
        setChildViewController(childController: HuoshanViewController(), title: "小视频", imageName: "huoshan")
        
         
    }
    
    func setChildViewController(childController : UIViewController,title : String, imageName :String){
        
        if UserDefaults.standard.bool(forKey: isNight) {
            setNightChildContriller(controller: childController, imageName: imageName)
        }else{
            setDayChildController(controller: childController, imageName: imageName);
        }
        //增加导航控制器
        childController.title = title
        let navVc = MyNavigationController(rootViewController: childController)
         addChildViewController(navVc)
        
        
    }
        /// 设置夜间控制器
    func setNightChildContriller(controller : UIViewController, imageName :String) {
        
        controller.tabBarItem.image = UIImage(named: imageName + "_tabbar_night_32x32_")
        controller.tabBarItem.selectedImage = UIImage(named: imageName + "_tabbar_press_night_32x32_")
    }
     /// 设置日间控制器
    func setDayChildController(controller : UIViewController,imageName : String) {
    
        controller.tabBarItem.image = UIImage(named: imageName + "_tabbar_32x32_")
        controller.tabBarItem.selectedImage = UIImage(named: imageName + "_tabbar_press_32x32_")
        
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
