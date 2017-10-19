//
//  LSSlideMenuController.swift
//  test20161130
//
//  Created by liu on 2017/4/15.
//  Copyright © 2017年 liu. All rights reserved.
//

import UIKit

@objc enum LSSlideMenuAnimationType: Int {
    /// 平移+缩放
    case Scale
    /// 平移
    case Move
}
@objc enum LSSlideMenuBeginArea: Int {
    /// width * 0.125
    case Edge
    /// width * 0.6
    case MoreThanHalf
    /// width * 1
    case All
    /// width * 0
    case Forbid
}
@objc enum LSSlideMenuMovingDirection: Int {
    /// 从左向右
    case Left
    /// 从右向左
    case Right
}

@objc enum LSSlideMenuControllerSlideStatus: Int {
    case Left ///< 正在展示leftVc
    case Main ///< 正在展示mainVc
    case Right ///< 正在展示rightVc
}

@objc protocol LSSlideMenuControllerDelegate {
    @objc optional func slideMenuVC(_ vc: LSSlideMenuController,
                                    beginAreaForDirection direction: LSSlideMenuMovingDirection) -> LSSlideMenuBeginArea
    @objc optional func slideMenuVC(_ vc: LSSlideMenuController,
                                    doAnimationOnView animationView: UIView,
                                    orginFrame: CGRect, xOffset: CGFloat)
}

class LSSlideMenuController: UIViewController, UIGestureRecognizerDelegate {
    
    // MARK: - public
    var leftSlideBeginArea: LSSlideMenuBeginArea = .Edge
    var rightSlideBeginArea: LSSlideMenuBeginArea = .Edge
    var leftViewShowWidth: CGFloat = kScreenWidth * 0.5  // 默认屏幕宽度的一半
    var rightViewShowWidth: CGFloat = kScreenWidth * 0.5 // 默认屏幕宽度的一半
    
    var animationDuration: TimeInterval = 0.35
    var needShowEdgeShadow: Bool = true
    var needShowCoverShadow: Bool = true
    var animationType: LSSlideMenuAnimationType = .Scale
    
    private(set) var slideStatus: LSSlideMenuControllerSlideStatus = .Main
    
    var mainVC: UIViewController? {
        didSet {
            if mainVC == oldValue {
                return
            }
            oldValue?.view.removeFromSuperview()
            oldValue?.removeFromParentViewController()
            if let mainVC = mainVC {
                self.addChildViewController(mainVC)
                self.mainVCContainer.addSubview(mainVC.view)
                mainVC.view.frame = self.mainVCContainer.bounds
                self.mainVCContainer.bringSubview(toFront: self.coverButton)
            }
        }
    }
    var leftVC: UIViewController? {
        didSet {
            if leftVC == oldValue {
                return
            }
            oldValue?.view.removeFromSuperview()
            oldValue?.removeFromParentViewController()
            if let leftVC = leftVC {
                self.addChildViewController(leftVC)
            }
        }
    }
    var rightVC: UIViewController? {
        didSet {
            if rightVC == oldValue {
                return
            }
            oldValue?.view.removeFromSuperview()
            oldValue?.removeFromParentViewController()
            if let rightVC = rightVC {
                self.addChildViewController(rightVC)
            }
        }
    }
    weak var delegate: LSSlideMenuControllerDelegate?
    
    override var childViewControllerForStatusBarStyle: UIViewController? {
        return self.mainVC
    }
    override var childViewControllerForStatusBarHidden: UIViewController? {
        return self.mainVC
    }
    
    func showLeftViewController(_ animated: Bool) {
        guard self.leftVC != nil else {
            return
        }
        self.willShowLeftViewController()
        
        var animatedTime: TimeInterval = 0
        if animated {
            animatedTime = Double(abs(leftViewShowWidth - mainVCContainer.frame.minX) /
                leftViewShowWidth) * animationDuration
        }
        UIView.animate(withDuration: animatedTime, delay: 0, options: .curveEaseInOut, animations: {
            self.layoutMainVCContainer(withOffset: self.leftViewShowWidth)
            self.showEdgeShadow(self.needShowEdgeShadow)
        }, completion: nil)
        
        self.slideStatus = .Left
    }
    func showRightViewController(_ animated: Bool) {
        guard self.rightVC != nil else {
            return
        }
        self.willShowRightViewController()
        
        var animatedTime: TimeInterval = 0
        if animated {
            animatedTime = Double(abs(rightViewShowWidth + mainVCContainer.frame.minX) /
                rightViewShowWidth) * animationDuration
        }
        UIView.animate(withDuration: animatedTime, delay: 0, options: .curveEaseInOut, animations: {
            self.layoutMainVCContainer(withOffset: -self.rightViewShowWidth)
            self.showEdgeShadow(self.needShowEdgeShadow)
        }, completion: nil)
        
        self.slideStatus = .Right
    }
    func hideSlideMenuViewController(_ animated: Bool) {
        self.showEdgeShadow(false)
        var animatedTime: TimeInterval = 0
        if animated {
            animatedTime = Double(abs(mainVCContainer.frame.minX /
                (mainVCContainer.frame.minX > 0 ? leftViewShowWidth : rightViewShowWidth)))
                * animationDuration
        }
        UIView.animate(withDuration: animatedTime, delay: 0, options: .curveEaseInOut, animations: {
            self.layoutMainVCContainer(withOffset: 0)
        }) { (finished) in
            self.leftVC?.view.removeFromSuperview()
            self.rightVC?.view.removeFromSuperview()
        }
        
        self.slideStatus = .Main
    }
    
    // MARK: - override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.mainVCContainer)
        self.showCoverShadow(0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        assert(mainVC != nil, "mainVC must be nunnull")
    }
    
    // MARK: - private
    private var leftPanBeginAreaWidth: CGFloat {
        var beginArea = self.leftSlideBeginArea
        if let method = self.delegate?.slideMenuVC(_:beginAreaForDirection:) {
            beginArea = method(self, .Left)
        }
        return self.panBeginAreaWidth(with: beginArea)
    }
    private var rightPanBeginAreaWidth: CGFloat {
        var beginArea = self.rightSlideBeginArea
        if let method = self.delegate?.slideMenuVC(_:beginAreaForDirection:) {
            beginArea = method(self, .Right)
        }
        return self.panBeginAreaWidth(with: beginArea)
    }
    private func panBeginAreaWidth(with beginArea: LSSlideMenuBeginArea) -> CGFloat {
        let width = self.mainVCContainer.bounds.width
        switch beginArea {
        case .Edge:
            return width * 0.125
        case .MoreThanHalf:
            return width * 0.6
        case .All:
            return width
        case .Forbid:
            return 0
        }
    }
    
    private func willShowLeftViewController() {
        guard let leftVC = self.leftVC, leftVC.view.superview == nil else {
            return
        }
        
        leftVC.view.frame = self.view.bounds
        self.view.insertSubview(leftVC.view, belowSubview: self.mainVCContainer)
        if let rightVC = self.rightVC, rightVC.view.superview != nil {
            rightVC.view.removeFromSuperview()
        }
    }
    private func willShowRightViewController() {
        guard let rightVC = self.rightVC, rightVC.view.superview == nil else {
            return
        }
        
        rightVC.view.frame = self.view.bounds
        self.view.insertSubview(rightVC.view, belowSubview: self.mainVCContainer)
        if let leftVC = self.leftVC, leftVC.view.superview != nil {
            leftVC.view.removeFromSuperview()
        }
    }
    private func showEdgeShadow(_ show: Bool) {
        self.mainVCContainer.layer.shadowOpacity = show ? 0.8 : 0
        if show {
            self.mainVCContainer.layer.cornerRadius = 4
            self.mainVCContainer.layer.shadowOffset = .zero
            self.mainVCContainer.layer.shadowRadius = 4
            self.mainVCContainer.layer.shadowPath =
                UIBezierPath(rect: self.mainVCContainer.bounds).cgPath
        }
    }
    private func showCoverShadow(_ ratio: CGFloat) {
        self.coverButton.backgroundColor =
            self.needShowCoverShadow ? UIColor.black : UIColor.clear
        self.coverButton.alpha = ratio * 0.4
    }
    // 重写此方法可以自定义mainViewController的出入动画
    private func layoutMainVCContainer(withOffset xOffset: CGFloat) {
        let totalWidth = self.view.frame.size.width
        let totalHeight = self.view.frame.size.height
        if xOffset == 0 {
            self.showCoverShadow(0)
        }
        else if xOffset > 0 {
            self.showCoverShadow(xOffset / leftViewShowWidth)
        }
        else {
            self.showCoverShadow(-xOffset / rightViewShowWidth)
        }
        
        if let method = self.delegate?.slideMenuVC(_:doAnimationOnView:orginFrame:xOffset:) {
            //如果有自定义的动画,则执行自定义动画
            method(self, self.mainVCContainer, self.view.bounds, xOffset)
            return
        }
        
        if self.animationType == .Move {
            self.mainVCContainer.frame = CGRect(x: xOffset, y: self.view.bounds.minY,
                                                width: totalWidth, height: totalHeight)
        } else {
            var scale = abs(totalHeight - abs(xOffset)) / totalHeight
            scale = max(0.8, scale)
            self.mainVCContainer.transform = CGAffineTransform(scaleX: scale, y: scale)
            if xOffset > 0 {
                self.mainVCContainer.frame = CGRect(x: xOffset,
                                                    y: self.view!.bounds.minY + (totalHeight * (1 - scale) / 2),
                                                    width: totalWidth * scale,
                                                    height: totalHeight * scale)
            } else {
                self.mainVCContainer.frame = CGRect(x: self.view!.frame.size.width * (1 - scale) + xOffset,
                                                    y: self.view!.bounds.minY + (totalHeight * (1 - scale) / 2),
                                                    width: totalWidth * scale,
                                                    height: totalHeight * scale)
            }
        }
    }
    
    private lazy var mainVCContainer: UIView = {
        let temp = UIView(frame: CGRect(x: 0, y: 0, width: kScreenWidth,
                                        height: kScreenHeight))
        temp.addSubview(self.coverButton)
        temp.addGestureRecognizer(self.panGestureRecognizer)
        return temp
    }()
    private lazy var coverButton: UIButton = {
        let temp = UIButton(frame: CGRect(x: 0, y: 0, width: kScreenWidth,
                                          height: kScreenHeight))
        temp.addTarget(self, action: #selector(self.hideSideViewController(_:)),
                       for: .touchUpInside)
        return temp
    }()
    private lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let temp = UIPanGestureRecognizer(target: self, action: #selector(self.pan(_:)))
        temp.delegate = self
        return temp
    }()
    
    private var startPanPoint: CGPoint!
    private var panMovingDirection: LSSlideMenuMovingDirection?
    
    @objc private func pan(_ pan: UIPanGestureRecognizer) {
        if pan.state == .began {
            startPanPoint = self.mainVCContainer.frame.origin
            if startPanPoint.x == 0 {
                self.showEdgeShadow(self.needShowEdgeShadow)
                let velocity = pan.velocity(in: self.view)
                if velocity.x > 0 {
                    self.willShowLeftViewController()
                }
                else if velocity.x < 0 {
                    self.willShowRightViewController()
                }
            }
            return
        }
        
        let translation = pan.translation(in: self.view)
        var xOffset = startPanPoint.x + translation.x
        if xOffset > 0 {
            if let leftVC = self.leftVC, leftVC.view.superview != nil {
                xOffset = min(xOffset, leftViewShowWidth)
            } else {
                xOffset = 0
            }
        }
        else if xOffset < 0 {
            if let rightVC = self.rightVC, rightVC.view.superview != nil {
                xOffset = max(xOffset, -rightViewShowWidth)
            } else {
                xOffset = 0
            }
        }
        if xOffset != self.mainVCContainer.frame.minX {
            self.layoutMainVCContainer(withOffset: xOffset)
        }
        
        if pan.state == .ended {
            let minX = self.mainVCContainer.frame.minX
            if minX == 0 {
                self.showEdgeShadow(false)
            } else {
                if panMovingDirection == .Left, minX > 20 {
                    self.showLeftViewController(true)
                }
                else if panMovingDirection == .Right, minX < -20 {
                    self.showRightViewController(true)
                }
                else {
                    self.hideSlideMenuViewController(true)
                }
            }
        } else {
            let velocity = pan.velocity(in: self.view)
            if velocity.x > 0 {
                panMovingDirection = .Left
            }
            else if velocity.x < 0 {
                panMovingDirection = .Right
            }
        }
    }
    @objc private func hideSideViewController(_ button: UIButton) {
        if self.mainVCContainer.frame.minX == 0 {
            return
        }
        self.hideSlideMenuViewController(true)
    }
    
    // MARK: - UIGestureRecognizerDelegate
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool
    {
        if gestureRecognizer == self.panGestureRecognizer {
            let pan = self.panGestureRecognizer
            let location = pan.location(in: self.mainVCContainer)
            let translation = pan.translation(in: self.view)
            let velocity = pan.velocity(in: self.view)
            
            if velocity.x > 600 || translation.x == 0 ||
                abs(translation.y) / abs(translation.x) > 1 {
                // 速度或者方向不合适
                return false;
            }
            if translation.x > 0 {
                // 向右
                if self.mainVCContainer.frame.minX < 0 {
                    return true
                }
                if self.leftVC == nil || location.x >= self.leftPanBeginAreaWidth {
                    return false
                }
            }
            else {
                // 向左
                if self.mainVCContainer.frame.minX > 0 {
                    return true
                }
                if self.rightVC == nil ||
                    location.x <= self.mainVCContainer.frame.width - self.rightPanBeginAreaWidth {
                    return false
                }
            }
            return true
        }
        return true
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        return true
    }
    
    // MARK: - visible vc
    override func lsVisibleViewController() -> UIViewController! {
        return self.mainVC
    }
}

