//
//  ViewController.swift
//  NEHotspotConfigurationDemo
//
//  Created by Matt Donahoe on 9/5/18.
//  Copyright © 2018
//

import NetworkExtension
import UIKit
import Foundation
import SystemConfiguration.CaptiveNetwork

let kNEHotspotConfigurationErrorDomain = "NEHotspotConfigurationErrorDomain"
let kErrorAlreadyAssociated = 13

class ViewController: UIViewController {

  @IBOutlet weak var statusLabel: UILabel?
  @IBOutlet weak var ssidInput: UITextField?
  @IBOutlet weak var passphraseInput: UITextField?
  @IBOutlet weak var connectButton: UIButton?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.statusLabel?.text = self.getWiFiSsid()
  }
  
  // TODO(matt): Is there a short example of Reachability?
  func getWiFiSsid() -> String? {
    var ssid: String?
    if let interfaces = CNCopySupportedInterfaces() as NSArray? {
      for interface in interfaces {
        if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
          ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
          break
        }
      }
    }
    return ssid
  }

  @IBAction func didTapConnect(_ sender : Any) {
    if let ssid = self.ssidInput?.text, let passphrase = self.passphraseInput?.text {
      let hotspotConfig = NEHotspotConfiguration(ssid: ssid, passphrase: passphrase, isWEP: false)
      self.statusLabel?.text = "Connecting to \(ssid)..."
      NEHotspotConfigurationManager.shared.apply(hotspotConfig) {[unowned self] (error) in
        if let error = error {
          if error._domain == kNEHotspotConfigurationErrorDomain && error._code == kErrorAlreadyAssociated {
            self.statusLabel?.text = "Connected"
          } else {
            self.statusLabel?.text = "Error: \(error.localizedDescription)"
          }
        } else {
          // TODO(matt): check current ssid.
          // If the desired ssid is not found, it might not be available.
          self.statusLabel?.text = "Applied"
        }
      }
    } else {
      self.statusLabel?.text = "error: blank"
    }
  }
  
  @IBAction func didTapRemove(_ sender : Any) {
    if let ssid = self.ssidInput?.text {
      NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
      self.statusLabel?.text = "Removed"
    } else {
      self.statusLabel?.text = "Error: blank"
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

}

