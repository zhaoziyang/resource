//
//  LocationDemoViewController.swift
//  BMKSwiftDemo
//
//  Created by wzy on 15/11/4.
//  Copyright © 2015年 baidu. All rights reserved.
//

import UIKit

class LocationDemoViewController: UIViewController, BMKMapViewDelegate, BMKLocationServiceDelegate {
    
    var locationService: BMKLocationService!
    
    @IBOutlet weak var _mapView: BMKMapView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var followHeadingButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 添加按钮
        let customRightBarButtonItem = UIBarButtonItem(title: "自定义精度圈", style: .plain, target: self, action: #selector(LocationDemoViewController.customLocationAccuracyCircle))
        self.navigationItem.rightBarButtonItem = customRightBarButtonItem
        
        locationService = BMKLocationService()
        locationService.allowsBackgroundLocationUpdates = true
        
        startButton.isEnabled = true
        stopButton.isEnabled = false
        followButton.isEnabled = false
        followHeadingButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locationService.delegate = self
        _mapView.delegate = self
        _mapView.viewWillAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        locationService.delegate = self
        _mapView.delegate = nil
        _mapView.viewWillDisappear()
    }
    
    //自定义精度圈
    func customLocationAccuracyCircle() {
        let param = BMKLocationViewDisplayParam()
        param.accuracyCircleStrokeColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.5)
        param.accuracyCircleFillColor = UIColor(red: 0, green: 1, blue: 0, alpha: 0.3)
        _mapView.updateLocationView(with: param)
    }
    
    // MARK: - IBAction
    @IBAction func startLocation(_ sender: AnyObject) {
        print("进入普通定位态");
        locationService.startUserLocationService()
        _mapView.showsUserLocation = false//先关闭显示的定位图层
        _mapView.userTrackingMode = BMKUserTrackingModeNone;//设置定位的状态
        _mapView.showsUserLocation = true//显示定位图层
        
        startButton.isEnabled = false
        stopButton.isEnabled = true
        followButton.isEnabled = true
        followHeadingButton.isEnabled = true
    }
    
    @IBAction func stopLocation(_ sender: AnyObject) {
        locationService.stopUserLocationService()
        _mapView.showsUserLocation = false
        
        startButton.isEnabled = true
        stopButton.isEnabled = false
        followButton.isEnabled = false
        followHeadingButton.isEnabled = false
    }
    
    @IBAction func followMode(_ sender: AnyObject) {
        print("进入跟随态");
        _mapView.showsUserLocation = false
        _mapView.userTrackingMode = BMKUserTrackingModeFollow
        _mapView.showsUserLocation = true
    }
    
    @IBAction func followHeadingMode(_ sender: AnyObject) {
        print("进入罗盘态");
        _mapView.showsUserLocation = false
        _mapView.userTrackingMode = BMKUserTrackingModeFollowWithHeading
        _mapView.showsUserLocation = true
    }
    
    
    // MARK: - BMKMapViewDelegate
   
    
    // MARK: - BMKLocationServiceDelegate
    
    /**
    *在地图View将要启动定位时，会调用此函数
    *@param mapView 地图View
    */
    func willStartLocatingUser() {
        print("willStartLocatingUser");
    }
    
    /**
    *用户方向更新后，会调用此函数
    *@param userLocation 新的用户位置
    */
    func didUpdateUserHeading(_ userLocation: BMKUserLocation!) {
        print("heading is \(userLocation.heading)")
        _mapView.updateLocationData(userLocation)
    }
    
    /**
    *用户位置更新后，会调用此函数
    *@param userLocation 新的用户位置
    */
    func didUpdate(_ userLocation: BMKUserLocation!) {
        print("didUpdateUserLocation lat:\(userLocation.location.coordinate.latitude) lon:\(userLocation.location.coordinate.longitude)")
        _mapView.updateLocationData(userLocation)
    }
    
    /**
    *在地图View停止定位后，会调用此函数
    *@param mapView 地图View
    */
    func didStopLocatingUser() {
        print("didStopLocatingUser")
    }

}
