//
//  SettingView.swift
//  SoundDemo
//
//  Created by Phil GoGear on 28/10/15.
//  Copyright © 2015 Gibson Innovations. All rights reserved.
//

import UIKit

class SettingView:UIView{
    /*class func instanceFromNib() -> UIView {
        return UINib(nibName: "SettingView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! UIView
    }*/

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadViewFromNib ()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadViewFromNib ()
    }
    func loadViewFromNib() {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "SettingView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as? UIView
        view?.frame = bounds
        //view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.addSubview(view!);
    }
    
    @IBAction func BacktoMain(sender: AnyObject) {
        
    }
    @IBAction func Continue(sender: AnyObject) {
        self.removeFromSuperview()
    }
}