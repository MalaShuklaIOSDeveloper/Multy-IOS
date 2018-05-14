//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import RealmSwift
import Alamofire
import CryptoSwift
//import BiometricAuthentication

private typealias ScrollViewDelegate = AssetsViewController
private typealias CollectionViewDelegate = AssetsViewController
private typealias CollectionViewDelegateFlowLayout = AssetsViewController
private typealias TableViewDelegate = AssetsViewController
private typealias TableViewDataSource = AssetsViewController
private typealias PresentingSheetDelegate = AssetsViewController
private typealias CancelDelegate = AssetsViewController
private typealias CreateWalletDelegate = AssetsViewController

class AssetsViewController: UIViewController, AnalyticsProtocol {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    weak var backupView: UIView?
    
    let presenter = AssetsPresenter()
    let progressHUD = ProgressHUD(text: Constants.AssetsScreen.progressString)
    
    var isSeedBackupOnScreen = false
    
    var isFirstLaunch = true
    
    var isFlowPassed = false
    
    var isSocketInitiateUpdating = false
    
    var isInsetCorrect = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.backUpView()
        
        tableView.accessibilityIdentifier = "AssetsTableView"
        view.isUserInteractionEnabled = false
        registerCells()
        presenter.assetsVC = self
        presenter.tabBarFrame = tabBarController?.tabBar.frame
        navigationController?.setNavigationBarHidden(true, animated: false)

        guard isFlowPassed else {
            self.view.isUserInteractionEnabled = true
            return
        }
        
        if !self.isFirstLaunch {
            self.presenter.updateWalletsInfo()
        }
        
        let isFirst = DataManager.shared.checkIsFirstLaunch()
        if isFirst {
            sendAnalyticsEvent(screenName: screenFirstLaunch, eventName: screenFirstLaunch)
            self.view.isUserInteractionEnabled = true
            return
        }
        
        sendAnalyticsEvent(screenName: screenMain, eventName: screenMain)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateExchange), name: NSNotification.Name("exchageUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateWalletAfterSockets), name: NSNotification.Name("transactionUpdated"), object: nil)
        
        let _ = MasterKeyGenerator.shared.generateMasterKey{_,_, _ in }
        
        checkOSForConstraints()

        self.view.addSubview(progressHUD)
        if self.presenter.account != nil {
            tableView.frame.size.height = screenHeight - tabBarController!.tabBar.frame.height
        }
        DataManager.shared.socketManager.start()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if self.presenter.isJailed {
            self.presentWarningAlert(message: Constants.Security.jailbrokenDeviceWarningString)
        }
        
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: presenter.account == nil)
        
        if !self.isFirstLaunch {
            self.presenter.updateWalletsInfo()
        }
        
        self.isFirstLaunch = false
        guard isFlowPassed == true else {
            return
        }

        self.tabBarController?.tabBar.frame = self.presenter.tabBarFrame!
        if self.presenter.account != nil {
            tableView.frame.size.height = screenHeight - tabBarController!.tabBar.frame.height
        }
    }
    
    override func viewDidLayoutSubviews() {
        if self.presenter.account != nil {
            tableView.frame.size.height = screenHeight - tabBarController!.tabBar.frame.height
        }
    }
    
    @objc func updateExchange() {
        for cell in self.tableView.visibleCells {
            if cell.isKind(of: WalletTableViewCell.self) {
                (cell as! WalletTableViewCell).fillInCell()
            }
        }
    }
    
    @objc func updateWalletAfterSockets() {
        if isSocketInitiateUpdating {
            return
        }
        
        if !isVisible() {
            return
        }
        
        isSocketInitiateUpdating = true
        presenter.getWalletVerboseForSockets { (_) in
            self.isSocketInitiateUpdating = false
            for cell in self.tableView.visibleCells {
                if cell.isKind(of: WalletTableViewCell.self) {
                    (cell as! WalletTableViewCell).fillInCell()
                }
            }
        }
    }
    
    func backUpView() {
        if backupView != nil {
            return
        }
        
        let view = UIView()
        if screenHeight == heightOfX {
            view.frame = CGRect(x: 16, y: 50, width: screenWidth - 32, height: Constants.AssetsScreen.backupButtonHeight)
        } else {
            view.frame = CGRect(x: 16, y: 25, width: screenWidth - 32, height: Constants.AssetsScreen.backupButtonHeight)
        }
        
        view.layer.cornerRadius = 20
        view.backgroundColor = #colorLiteral(red: 0.9229970574, green: 0.08180250973, blue: 0.2317947149, alpha: 1)
        view.layer.shadowColor = #colorLiteral(red: 0.4156862745, green: 0.1490196078, blue: 0.168627451, alpha: 0.6)
        view.layer.shadowOpacity = 1
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 10
        view.isHidden = false
        let image = UIImageView()
        image.image = #imageLiteral(resourceName: "warninngBigWhite")
        image.frame = CGRect(x: 13, y: 11, width: 22, height: 22)
        
        let chevronImg = UIImageView(frame: CGRect(x: view.frame.width - 24, y: 15, width: 13, height: 13))
        chevronImg.image = #imageLiteral(resourceName: "chevron__")
        let btn = UIButton()
        btn.frame = CGRect(x: 50, y: 0, width: view.frame.width - 35, height: view.frame.height)
        btn.setTitle("Backup is needed!", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont(name: "Avenir-Next", size: 6)
        btn.contentHorizontalAlignment = .left
        btn.addTarget(self, action: #selector(goToSeed), for: .touchUpInside)
        
        view.addSubview(btn)
        view.addSubview(image)
        view.addSubview(chevronImg)
        backupView = view
        self.view.addSubview(backupView!)
        view.isHidden = true
        view.isUserInteractionEnabled = false
    }
    
    @objc func goToSeed() {
        sendAnalyticsEvent(screenName: screenMain, eventName: backupSeedTap)
        let stroryboard = UIStoryboard(name: "SeedPhrase", bundle: nil)
        let vc = stroryboard.instantiateViewController(withIdentifier: "seedAbout")
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK: Setup functions
    
    func checkOSForConstraints() {
        if #available(iOS 11.0, *) {
            //OK: Storyboard was made for iOS 11
        } else {
            self.tableViewTopConstraint.constant = 0
        }
    }
    
    func registerCells() {
        let walletCell = UINib.init(nibName: "WalletTableViewCell", bundle: nil)
        self.tableView.register(walletCell, forCellReuseIdentifier: "walletCell")
        
        let portfolioCell = UINib.init(nibName: "PortfolioTableViewCell", bundle: nil)
        self.tableView.register(portfolioCell, forCellReuseIdentifier: "portfolioCell")
        
        let newWalletCell = UINib.init(nibName: "NewWalletTableViewCell", bundle: nil)
        self.tableView.register(newWalletCell, forCellReuseIdentifier: "newWalletCell")
        
        let textCell = UINib.init(nibName: "TextTableViewCell", bundle: nil)
        self.tableView.register(textCell, forCellReuseIdentifier: "textCell")
        
        let logoCell = UINib.init(nibName: "LogoTableViewCell", bundle: nil)
        self.tableView.register(logoCell, forCellReuseIdentifier: "logoCell")
        
        let createOrRestoreCell = UINib.init(nibName: "CreateOrRestoreBtnTableViewCell", bundle: nil)
        self.tableView.register(createOrRestoreCell, forCellReuseIdentifier: "createOrRestoreCell")
    }
    
    func goToWalletVC(indexPath: IndexPath) {
        let walletVC = presenter.getWalletViewController(indexPath: indexPath)
        self.navigationController?.pushViewController(walletVC, animated: true)
    }
    
    func updateUI() {
        self.tableView.reloadData()
    }
    
    func presentWarningAlert(message: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let slpashScreen = storyboard.instantiateViewController(withIdentifier: "splash") as! SplashViewController
        slpashScreen.isJailAlert = 1
        self.present(slpashScreen, animated: true, completion: nil)
    }
    
    func presentUpdateAlert() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let slpashScreen = storyboard.instantiateViewController(withIdentifier: "splash") as! SplashViewController
        slpashScreen.isJailAlert = 0
        self.present(slpashScreen, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.Storyboard.createWalletVCSegueID {
            let createVC = segue.destination as! CreateWalletViewController
            createVC.presenter.account = presenter.account
        }
    }
    
    func presentTermsOfService() {
        if DataManager.shared.checkTermsOfService() {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let termsVC = storyBoard.instantiateViewController(withIdentifier: "termsVC")
            self.present(termsVC, animated: true, completion: nil)
        }
    }
}

extension CreateWalletDelegate: CreateWalletProtocol {
    func goToCreateWallet() {
        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: true)
        self.performSegue(withIdentifier: Constants.Storyboard.createWalletVCSegueID, sender: Any.self)
    }
}

extension CancelDelegate: CancelProtocol {
    func cancelAction() {
        presentDonationVCorAlert()
    }
    
    func presentNoInternet() {
        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: presenter.account == nil)
    }
}

extension PresentingSheetDelegate: OpenCreatingSheet {
    //MARK: CreateNewWalletProtocol
    func openNewWalletSheet() {
        if self.presenter.account == nil {
            return
        }
        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: true)
        sendAnalyticsEvent(screenName: screenMain, eventName: createWalletTap)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let creatingVC = storyboard.instantiateViewController(withIdentifier: "creatingVC") as! CreatingWalletActionsViewController
        creatingVC.cancelDelegate = self
        creatingVC.createProtocol = self
        creatingVC.modalPresentationStyle = .custom
        creatingVC.modalTransitionStyle = .crossDissolve
        self.present(creatingVC, animated: true, completion: nil)
    }
}

extension TableViewDelegate : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presenter.tappedIndexPath = indexPath
        
        switch indexPath {
        case [0,0]:
            sendAnalyticsEvent(screenName: screenMain, eventName: logoTap)
            break
        case [0,1]:
            break
        case [0,2]:
            if self.presenter.account == nil {
                sendAnalyticsEvent(screenName: screenFirstLaunch, eventName: createFirstWalletTap)
                self.performSegue(withIdentifier: "createWalletVC", sender: Any.self)
            } else {
                if self.presenter.isWalletExist() {
                    goToWalletVC(indexPath: indexPath)
                } else {
                    break
                }
            }
        case [0,3]:
            if self.presenter.account == nil {
                sendAnalyticsEvent(screenName: screenFirstLaunch, eventName: restoreMultyTap)
                let storyboard = UIStoryboard(name: "SeedPhrase", bundle: nil)
                let backupSeedVC = storyboard.instantiateViewController(withIdentifier: "backupSeed") as! CheckWordsViewController
                backupSeedVC.isRestore = true
                self.navigationController?.pushViewController(backupSeedVC, animated: true)
            } else {
                if self.presenter.isWalletExist() {
                    goToWalletVC(indexPath: indexPath)
                }
            }
        default:
            if self.presenter.isWalletExist() {
                goToWalletVC(indexPath: indexPath)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath {
        case [0,0]:         // PORTFOLIO CELL  or LOGO
            if presenter.account == nil {
                return 220
            } else {
                if presenter.account!.isSeedPhraseSaved() {
                    return 340
                } else {
                    return 340 + Constants.AssetsScreen.backupAssetsOffset
                }
            }
        case [0,1]:        // !!!NEW!!! WALLET CELL
            return 75
        case [0,2]:
            if self.presenter.account != nil {
                if presenter.isWalletExist() {
                    return 104
                } else {
                    return 121
                }
            } else {   // acc == nil
                return 100
            }
        case [0,3]:
            if self.presenter.account != nil {
                return 104
            } else {
                return 100
            }
        default:
            return 104
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath {
        case [0,0]:         // PORTFOLIO CELL  or LOGO
            if presenter.account == nil {
                return 220
            } else {
                if presenter.account!.isSeedPhraseSaved() {
                    return 340
                } else {
                    return 340 + Constants.AssetsScreen.backupAssetsOffset
                }
            }
        case [0,1]:        // !!!NEW!!! WALLET CELL
            return 75
        case [0,2]:
            if self.presenter.account != nil {
                if presenter.isWalletExist() {
                    return 104
                } else {
                    return 121
                }
            } else {   // acc == nil
                return 100
            }
        case [0,3]:
            if self.presenter.account != nil {
                return 104
            } else {
                return 100
            }
        default:
            return 104
        }
    }
    
    override var preferredContentSize: CGSize {
        get {
            self.tableView.layoutIfNeeded()
            return self.tableView.contentSize
        }
        set { }
    }
}

extension TableViewDataSource : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.presenter.account != nil {
            if presenter.isWalletExist() {
                return 2 + presenter.account!.wallets.count  // logo / new wallet /wallets
            } else {
                return 3                                     // logo / new wallet / text cell
            }
        } else {
            return 4                                         // logo / empty cell / create wallet / restore
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath {
        case [0,0]:         // PORTFOLIO CELL  or LOGO
            if presenter.account == nil {
                let logoCell = self.tableView.dequeueReusableCell(withIdentifier: "logoCell") as! LogoTableViewCell
                return logoCell
            } else {
                let portfolioCell = self.tableView.dequeueReusableCell(withIdentifier: "portfolioCell") as! PortfolioTableViewCell
                portfolioCell.mainVC = self
                portfolioCell.delegate = self
                
                return portfolioCell
            }
        case [0,1]:        // !!!NEW!!! WALLET CELL
            let newWalletCell = self.tableView.dequeueReusableCell(withIdentifier: "newWalletCell") as! NewWalletTableViewCell
            newWalletCell.delegate = self
            
            if presenter.account == nil {
                newWalletCell.hideAll(flag: true)
            } else {
                newWalletCell.hideAll(flag: false)
            }
            
            return newWalletCell
        case [0,2]:
            if self.presenter.account != nil {
                //MARK: change logiv
                
                if presenter.isWalletExist() {
                    let walletCell = self.tableView.dequeueReusableCell(withIdentifier: "walletCell") as! WalletTableViewCell
                    //                    walletCell.makeshadow()
                    walletCell.wallet = presenter.account?.wallets[indexPath.row - 2]
                    walletCell.accessibilityIdentifier = "\(indexPath.row - 2)"
                    walletCell.fillInCell()
                    
                    return walletCell
                } else {
                    let textCell = self.tableView.dequeueReusableCell(withIdentifier: "textCell") as! TextTableViewCell
                    
                    return textCell
                }
            } else {   // acc == nil
                let createCell = self.tableView.dequeueReusableCell(withIdentifier: "createOrRestoreCell") as! CreateOrRestoreBtnTableViewCell
                
                return createCell
            }
        case [0,3]:
            if self.presenter.account != nil {
                let walletCell = self.tableView.dequeueReusableCell(withIdentifier: "walletCell") as! WalletTableViewCell
                //                walletCell.makeshadow()
                walletCell.wallet = presenter.account?.wallets[indexPath.row - 2]
                walletCell.accessibilityIdentifier = "\(indexPath.row - 2)"
                walletCell.fillInCell()
                
                return walletCell
            } else {
                let restoreCell = self.tableView.dequeueReusableCell(withIdentifier: "createOrRestoreCell") as! CreateOrRestoreBtnTableViewCell
                restoreCell.makeRestoreCell()
                
                return restoreCell
            }
        default:
            let walletCell = self.tableView.dequeueReusableCell(withIdentifier: "walletCell") as! WalletTableViewCell
            
            walletCell.wallet = presenter.account?.wallets[indexPath.row - 2]
            walletCell.accessibilityIdentifier = "\(indexPath.row - 2)"
            walletCell.fillInCell()
            
            return walletCell
        }
    }
}

extension CollectionViewDelegateFlowLayout : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: screenWidth, height: 277 /* (screenWidth / 375.0)*/)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, 0, 0, 0)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension CollectionViewDelegate : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        unowned let weakSelf =  self
        self.presentDonationAlertVC(from: weakSelf)
        (tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: true)
        
        logAnalytics(indexPath: indexPath)
    }
    
    func logAnalytics(indexPath: IndexPath) {
        let eventCode = indexPath.row == 0 ? donationForPortfolioSC : donationForChartsSC
        sendDonationAlertScreenPresentedAnalytics(code: eventCode)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let firstCell = self.tableView.cellForRow(at: [0,0]) else { return }
        (firstCell as! PortfolioTableViewCell).pageControl.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard let firstCell = self.tableView.cellForRow(at: [0,0]) else { return }
        (firstCell as! PortfolioTableViewCell).pageControl.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
    }
}
