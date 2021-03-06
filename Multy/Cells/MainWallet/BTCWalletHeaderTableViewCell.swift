//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import RealmSwift

class BTCWalletHeaderTableViewCell: UITableViewCell, UICollectionViewDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var pageControll: UIPageControl!
    @IBOutlet weak var titleLbl: UILabel!
    
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    var mainVC: BTCWalletViewController?
    
    var wallet: UserWalletRLM? {
        didSet {
            self.setupUI()
        }
     }
    
    var blockedAmount = UInt64()
    
    weak var delegate : UICollectionViewDelegate? {
        didSet {
            self.collectionView.delegate = delegate
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        
        let headerCollectionCell = UINib.init(nibName: "MainWalletCollectionViewCell", bundle: nil)
        self.collectionView.register(headerCollectionCell, forCellWithReuseIdentifier: "MainWalletCollectionViewCellID")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setupPageControl() {
//        self.pageControll.numberOfPages = 2
        
    }
    
    func setupUI() {
        if wallet != nil {
            self.titleLbl.text = wallet?.name
            self.collectionView.reloadData()
            if screenHeight == heightOfX {
                self.topConstraint.constant = 50
            }
//            self.pageControll.numberOfPages = (self.wallet?.addresses.count)!
        }
    }
    
    @IBAction func closeAction(_ sender: Any) {
        self.mainVC?.closeAction()
    }
    
    @IBAction func settingsAction(_ sender: Any) {
        self.mainVC?.settingsAction(sender)
    }
}

extension BTCWalletHeaderTableViewCell: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return (self.wallet?.addresses.count)!
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "MainWalletCollectionViewCellID", for: indexPath) as! BTCWalletHeaderCollectionViewCell
        cell.mainVC = self.mainVC
        cell.wallet = self.wallet
        cell.blockedAmount = self.blockedAmount
        cell.fillInCell()
        
        return cell
    }
    
    func updateUI() {
        self.collectionView.reloadData()
    }
}
