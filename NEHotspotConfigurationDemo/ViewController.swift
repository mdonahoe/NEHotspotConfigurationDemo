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
  
  // TODO(matt): How do we get notified of ssid changes?
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
    guard let ssid = self.ssidInput?.text, ssid != "" else {
      self.statusLabel?.text = "Error: blank ssid"
      return
    }
    if let passphrase = self.passphraseInput?.text {
      self.statusLabel?.text = "Connecting to \(ssid)..."
      let hotspotConfig = NEHotspotConfiguration(ssid: ssid, passphrase: passphrase, isWEP: false)
      NEHotspotConfigurationManager.shared.apply(hotspotConfig) {[unowned self] (error) in
        if let error = error {
          if error._domain == kNEHotspotConfigurationErrorDomain && error._code == kErrorAlreadyAssociated {
            // NOTE: This error happens if we ask to connect to a network to which we already are associated.
            // The request fails to apply, but we don't care since we are already connected.
            self.statusLabel?.text = "Connected"
          } else {
            self.statusLabel?.text = "Error: \(error.localizedDescription)"
          }
        } else {
          // NOTE: This branch can execute even if the ssid was not successfully joined. Check if we are on the expected ssid
          if let currentSsid = self.getWiFiSsid(), currentSsid == self.ssidInput?.text {
            self.statusLabel?.text = "Joined \(currentSsid)"
          } else {
            self.statusLabel?.text = "Not found"
          }
        }
      }
    }
  }
  
  @IBAction func didTapRemove(_ sender : Any) {
    guard let ssid = self.ssidInput?.text, ssid != "" else {
      self.statusLabel?.text = "Error: blank ssid"
      return
    }
    // NOTE: a side-effect of removing a configuration is disconnecting from that ssid.
    NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
    self.statusLabel?.text = "Removing..."
    // Wait a couple seconds for the wifi to switch
    // TODO(matt): use a notification instead.
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
      self?.statusLabel?.text = self?.getWiFiSsid()
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

}

