//
//  RadarNearbyViewController.swift
//  BMKSwiftDemo
//
//  Created by wzy on 15/11/9.
//  Copyright © 2015年 baidu. All rights reserved.
//

import UIKit

class RadarNearbyViewController: UIViewController, BMKMapViewDelegate, BMKRadarManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var segControl: UISegmentedControl!
    @IBOutlet weak var preButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var curPageLabel: UILabel!
 
    var tableView: UITableView!
    var _mapView: BMKMapView!
    
    var radarManager: BMKRadarManager! = BMKRadarManager.getInstance()
    
    var myCoor = CLLocationCoordinate2D()
    
    var curPageIndex = 0
    var nearbyInfos = [BMKRadarNearbyInfo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "周边雷达-检索"
        self.tabBarItem.title = "检索周边"
        
        let rect = scrollView.frame
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width * 2, height: scrollView.frame.size.height);
        tableView = UITableView(frame: CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height - 30))
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = true
        tableView.clipsToBounds = true
        scrollView.addSubview(tableView)
        _mapView = BMKMapView(frame: CGRect(x: rect.size.width, y: 0, width: rect.size.width, height: rect.size.height))
        _mapView.showsUserLocation = true;
        scrollView.addSubview(_mapView)
        
        preButton.isEnabled = false
        nextButton.isEnabled = false
        curPageLabel.isHidden = false
        curPageLabel.text = ""
        
        ///我的位置改变通知
        NotificationCenter.default.addObserver(self, selector: #selector(RadarNearbyViewController.updateMyLocation(_:)), name: NSNotification.Name(rawValue: MY_LOCATION_UPDATE_NOTIFICATION), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _mapView.viewWillAppear()
        _mapView.delegate = self
        radarManager.add(self)//添加radar delegate
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        _mapView.viewWillDisappear()
        _mapView.delegate = nil
        radarManager.remove(self)//不用需移除，否则影响内存释放
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        radarManager = nil
        BMKRadarManager.releaseInstance()
    }


    // MARK: - IBAction
    ///获取周边信息
    @IBAction func nearbyAction(_ sender: UIButton) {
        nearbySearchWithPageIndex(0)
    }
    ///清除本地缓存
    @IBAction func clearAction(_ sender: UIButton) {
        updateNearbyInfos([BMKRadarNearbyInfo]())
        preButton.isEnabled = false
        nextButton.isEnabled = false
        curPageLabel.text = ""
    }
    ///切换附近信息显示方式
    @IBAction func switchResShowAction(_ sender: UISegmentedControl) {
        let x = scrollView.frame.size.width * CGFloat(segControl.selectedSegmentIndex)
        scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
    }
    
    ///上一页
    @IBAction func prePageAction(_ sender: UIButton) {
        nearbySearchWithPageIndex(curPageIndex - 1)
    }
    ///下一页
    @IBAction func nextPageAction(_ sender: UIButton) {
        nearbySearchWithPageIndex(curPageIndex + 1)
    }
    
    func nearbySearchWithPageIndex(_ pageIndex: Int) {
        if pageIndex < 0 {
            return
        }
        let option = BMKRadarNearbySearchOption()
        option.radius = 8000
        option.sortType = BMK_RADAR_SORT_TYPE_DISTANCE_FROM_NEAR_TO_FAR
        option.centerPt = myCoor
        option.pageIndex = pageIndex
        option.pageCapacity = 2
        let res = radarManager.getRadarNearbySearchRequest(option)
        if res {
            print("get 请求成功")
        } else {
            print("get 请求失败")
        }
    }
    
    // MARK: - BMKRadarManagerDelegate
    /**
    *返回雷达 查询周边的用户信息结果
    *@param result 结果，类型为@see BMKRadarNearbyResult
    *@param error 错误号，@see BMKRadarErrorCode
    */
    func onGetRadarNearbySearch(_ result: BMKRadarNearbyResult!, error: BMKRadarErrorCode) {
        print("onGetRadarNearbySearchResult: \(error)")
        if error == BMK_RADAR_NO_ERROR {
            print("result.infoList.count: \(result.infoList.count)")
            updateNearbyInfos(result.infoList as! [BMKRadarNearbyInfo])
            curPageIndex = result.pageIndex
            curPageLabel.text = "\(curPageIndex + 1)"
            nextButton.isEnabled = (curPageIndex + 1 != result.pageNum)
            preButton.isEnabled = curPageIndex != 0
        }
    }


    // MARK: - UITableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nearbyInfos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let CellIdentifier = "BaiduMapRadarDemoCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        if  cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: CellIdentifier)
        }
        let info = nearbyInfos[indexPath.row]
        cell!.textLabel!.text = info.userId
        cell!.detailTextLabel!.text = "\(info.distance)米   \(info.extInfo)"
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let annotation = _mapView.annotations[indexPath.row] as! BMKAnnotation
        _mapView.centerCoordinate = annotation.coordinate
        _mapView.selectAnnotation(annotation, animated: false)
        segControl.selectedSegmentIndex = 1
        switchResShowAction(segControl)
    }
    
    // MARK: - BMKMapViewDelegate
    /**
    *根据anntation生成对应的View
    *@param mapView 地图View
    *@param annotation 指定的标注
    *@return 生成的标注View
    */
    func mapView(_ mapView: BMKMapView!, viewFor annotation: BMKAnnotation!) -> BMKAnnotationView! {
        let AnnotationViewID = "renameMark"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: AnnotationViewID) as! BMKPinAnnotationView?
        if annotationView == nil {
            annotationView = BMKPinAnnotationView(annotation: annotation, reuseIdentifier: AnnotationViewID)
            // 设置颜色
            annotationView!.pinColor = UInt(BMKPinAnnotationColorRed)
            // 从天上掉下的动画
            annotationView!.animatesDrop = true
            // 设置是否可以拖拽
            annotationView!.isDraggable = false
        }
        annotationView?.annotation = annotation
        return annotationView
    }
    
    // MARK: - 
    ///更新缓存附近信息数据并刷新地图显示
    func updateNearbyInfos(_ infos: [BMKRadarNearbyInfo]) {
        nearbyInfos.removeAll()
        nearbyInfos.append(contentsOf: infos)
        
        tableView.reloadData()
        _mapView.removeAnnotations(_mapView.annotations)
        
        var annotations = [BMKPointAnnotation]()
        for info in nearbyInfos {
            let annotation = BMKPointAnnotation()
            annotation.coordinate = info.pt
            annotation.title = info.userId
            annotation.subtitle = info.extInfo
            annotations.append(annotation)
        }
        _mapView.addAnnotations(annotations)
        _mapView.showAnnotations(annotations, animated: true)
    }
    
    ///更新我的位置
    func updateMyLocation(_ notification: Notification) {
        if let location = notification.userInfo!["loc"] as? BMKUserLocation {
            myCoor = location.location.coordinate
            _mapView.updateLocationData(location)
        }
    }

}
