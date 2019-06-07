/**
       This file is part of Adguard for iOS (https://github.com/AdguardTeam/AdguardForiOS).
       Copyright © Adguard Software Limited. All rights reserved.
 
       Adguard for iOS is free software: you can redistribute it and/or modify
       it under the terms of the GNU General Public License as published by
       the Free Software Foundation, either version 3 of the License, or
       (at your option) any later version.
 
       Adguard for iOS is distributed in the hope that it will be useful,
       but WITHOUT ANY WARRANTY; without even the implied warranty of
       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
       GNU General Public License for more details.
 
       You should have received a copy of the GNU General Public License
       along with Adguard for iOS.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation

class DnsSettingsController : UITableViewController{
    
    //MARK: - IB Outlets
    
    @IBOutlet weak var enabledSwitch: UISwitch!
    @IBOutlet weak var serverName: ThemableLabel!
    @IBOutlet weak var tunnelDescription: ThemableLabel!
    
    @IBOutlet var themableLabels: [ThemableLabel]!
    
    // MARK: - services
    
    private let vpnManager: APVPNManager = ServiceLocator.shared.getService()!
    private let theme: ThemeServiceProtocol = ServiceLocator.shared.getService()!
    
    private var observation: NSKeyValueObservation?
    
    // MARK: - view controller life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        observation = vpnManager.observe(\.tunnelMode) { [weak self] (mode, change) in
            DispatchQueue.main.async {
                self?.updateUI()
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.APVpnChanged, object: nil, queue: nil) {
            [weak self] (notification) in
            guard let sSelf = self else { return }
            sSelf.enabledSwitch.isOn = sSelf.vpnManager.enabled
            if sSelf.vpnManager.lastError != nil {
                ACSSystemUtils.showSimpleAlert(for: sSelf, withTitle: nil, message: sSelf.vpnManager.lastError?.localizedDescription)
            }
        }
        
        self.updateUI()
        
        updateTheme()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        theme.setupTableCell(cell)
        return cell
    }
    
    // MARK: Actions
    @IBAction func toggleEnableSwitch(_ sender: UISwitch) {
        
        let enabled = sender.isOn
        
        if enabled && !vpnManager.vpnInstalled {
            ACSSystemUtils.showSimpleAlert(for: self,
                                           withTitle: ACLocalizedString("vpn_alert_title", nil),
                                           message: ACLocalizedString("vpn_alert_message", nil)){
                self.vpnManager.enabled = enabled
            }
        }
        else {
            self.vpnManager.enabled = enabled
        }
    }

    
    // MARK: private methods
    
    private func updateUI() {
        enabledSwitch.isOn = vpnManager.enabled
        
        if vpnManager.isCustomServerActive() {
            serverName.text = vpnManager.activeDnsServer!.name
        }
        else if vpnManager.activeDnsServer?.dnsProtocol == nil {
            serverName.text = ACLocalizedString("no_dns_server_selected", nil)
        }
        else {
            let server = vpnManager.activeDnsProvider?.name ?? vpnManager.activeDnsServer?.name ?? ""
            let protocolName = ACLocalizedString(DnsProtocol.stringIdByProtocol[vpnManager.activeDnsServer!.dnsProtocol!], nil)
            serverName.text = "\(server) (\(protocolName))"
        }
        
        switch (vpnManager.tunnelMode) {
        case APVpnManagerTunnelModeSplit:
            tunnelDescription.text = ACLocalizedString("tunnel_mode_split_description", nil)
        case APVpnManagerTunnelModeFull:
            tunnelDescription.text = ACLocalizedString("tunnel_mode_full_description", nil)
        case APVpnManagerTunnelModeFullWithoutVPNIcon:
            tunnelDescription.text = ACLocalizedString("tunnel_mode_full_without_icon_description", nil)
        default:
            break
        }
    }
    
    private func updateTheme() {
        view.backgroundColor = theme.backgroundColor
        theme.setupLabels(themableLabels)
        theme.setupTable(tableView)
    }
}