//
//  ItemsViewController.swift
//  LootLogger
//
//  Created by Guillermo Padilla Lam on 10/06/20.
//  Copyright © 2020 gp Apps. All rights reserved.
//

import UIKit

class ItemsViewController : UITableViewController {
    
    var itemStore: ItemStore!
    var imageStore: ImageStore!
    
    let moreThan50Section = 0
    let otherSection = 1
    
    var showOnlyFavorites = false
    
    @IBOutlet weak var btnFavorites: UIButton!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        navigationItem.leftBarButtonItem = editButtonItem
        navigationItem.backBarButtonItem?.title = "Log"
    }
    
    var isEmptySectionMoreThan50: Bool {
        get { return itemStore.allItems.filter{ item in showableFilter(item, moreThan50Section)}.count == 0 }
    }
    
    var isEmptyOtherSection: Bool {
        get { return itemStore.allItems.filter{ item in showableFilter(item, otherSection)}.count == 0 }
    }
    
    lazy var showableFilter: (_ item: Item, _ section: Int) -> Bool = {(item, section) in
        if self.showOnlyFavorites {
            return self.getSectionOf(item: item) == section && item.isFavorite == true
        } else {
            return self.getSectionOf(item: item) == section
        }
    }
    
    func addEmptyStoreRow(indexPath: IndexPath) {
        tableView.insertRows(at: [indexPath], with: .automatic)
    }
    
    override func viewDidLoad() {
        addEmptyStoreRow(indexPath: IndexPath(row: 0, section: moreThan50Section))
        addEmptyStoreRow(indexPath: IndexPath(row: 0, section: otherSection))
        
        tableView.rowHeight = UITableView.automaticDimension // this is the defaukt value
        //tableView.estimatedRowHeight = 65 // improves the performance
    }
    
    @IBAction func showFavorites(_ sender: UIButton) {
        
        showOnlyFavorites = !showOnlyFavorites
        btnFavorites.setTitle(showOnlyFavorites ? "Show all" : "Favorites", for: .normal)
        
        tableView.reloadData()
    }
    
    @IBAction func addNewItem(_ sender: UIBarButtonItem) {
        
        let _isEmptySectionMoreThan50 = isEmptySectionMoreThan50
        let _isEmptyOtherSection = isEmptyOtherSection
        
        let newItem = itemStore.createItem()
        
        //  I get the section of the new item
        let section = getSectionOf(item: newItem)
        
        //  when empty rows, don´t add another one
        if (section == moreThan50Section && _isEmptySectionMoreThan50) ||
            (section == otherSection && _isEmptyOtherSection) {
            tableView.reloadData()
            return
        }
        
        //  I calculate the index based on the array of items in the same section
        if let index = itemStore.allItems.filter({ item in showableFilter( item, section) })  .firstIndex(of: newItem) {
            
            let indexPath = IndexPath(row: index, section: section)
            tableView.insertRows(at: [indexPath], with: .automatic)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (section == moreThan50Section && isEmptySectionMoreThan50) ||
            (section == otherSection && isEmptyOtherSection) {
            return 1
        } else {
            
            let moreThan50SectionCount = itemStore.allItems.filter { item in showableFilter( item, moreThan50Section) } .count
            let otherSectionCount = itemStore.allItems.filter { item in showableFilter( item, otherSection) } .count
            
            if section == moreThan50Section {
                return moreThan50SectionCount
            } else {
                return otherSectionCount
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        // insted of create a new UITableViewCell, lets use reuse
        //let tableCell = UITableViewCell(style: .value1, reuseIdentifier: "UITableViewCell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath) as! ItemCell
     
        if (indexPath.section == moreThan50Section && isEmptySectionMoreThan50) ||
            (indexPath.section == otherSection && isEmptyOtherSection) {
        
            cell.valueLabel.text = ""
            cell.serialNumberLabel.text = ""
            cell.nameLabel.text = "No items!"
        } else {
            
            let item = itemStore.allItems.filter{ item in showableFilter( item, indexPath.section) } [indexPath.row]
            
            cell.valueLabel.text = "$\(item.valueInDollars)"
            cell.serialNumberLabel.text = item.serialNumber
            cell.nameLabel.text = "\(item.name) \(item.isFavorite ? "(favorite)" : "")"
            
            cell.valueLabel.textColor = Double(item.valueInDollars) > 50 ? .green : .red
            
        }
        
        return cell
    
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            if (indexPath.section == moreThan50Section && isEmptySectionMoreThan50) ||
                (indexPath.section == otherSection && isEmptyOtherSection) {
                return
            }
            
            // I filter by section before get the index
            let item = itemStore.allItems.filter{ item in showableFilter( item, indexPath.section) }[indexPath.row]
            
            itemStore.removeItem(item)
            
            //  remove the item´s image from the image store
            imageStore.deleteImage(forKey: item.itemKey)
            
            if indexPath.row != 0 {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            } else {
                tableView.reloadData()
            }
            
        }
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        if (sourceIndexPath.section == moreThan50Section && isEmptySectionMoreThan50) ||
            (sourceIndexPath.section == otherSection && isEmptyOtherSection) {
            return
        }
        
        if sourceIndexPath.section != destinationIndexPath.section { return }
        
        let arrayBySection = itemStore.allItems.filter{ item in showableFilter( item, sourceIndexPath.section) }
        
        let originalSourceItem = arrayBySection[sourceIndexPath.row]
        let originalSourceIndex = itemStore.allItems.firstIndex(of: originalSourceItem)
        
        
        let originalDestinationItem = arrayBySection[destinationIndexPath.row]
        let originalDestinationIndex = itemStore.allItems.firstIndex(of: originalDestinationItem)
        
        itemStore.moveItem(from: originalSourceIndex!, to: originalDestinationIndex!)
        
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        if (sourceIndexPath.section == moreThan50Section && isEmptySectionMoreThan50) ||
            (sourceIndexPath.section == otherSection && isEmptyOtherSection) {
            return sourceIndexPath
        }
        
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            return sourceIndexPath
        } else {
            return proposedDestinationIndexPath
        }
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let isFavorite = itemStore.allItems.filter{ item in showableFilter( item, indexPath.section) }[indexPath.row].isFavorite
        
        let title = isFavorite ?
        NSLocalizedString("Unfavorite", comment: "Unfavorite") :
        NSLocalizedString("Favorite", comment: "Favorite")

        let action = UIContextualAction(style: .normal, title: title, handler: { (action, view, completionHandler) in
            self.itemStore.allItems.filter{ item in self.showableFilter( item, indexPath.section) }[indexPath.row].isFavorite = !isFavorite
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.tableView.reloadData()
            }
            
            completionHandler(true)
        })
        
        action.image = UIImage(named: "heart")
        action.backgroundColor = isFavorite ? .red : .green
        
        return UISwipeActionsConfiguration(actions: [action])
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if (indexPath.section == moreThan50Section && isEmptySectionMoreThan50) ||
            (indexPath.section == otherSection && isEmptyOtherSection) {
            return false
        }
        
        return true
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == moreThan50Section {
            return "More than $50"
        } else {
            return "$50 or less"
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case "showItem":
            // figure out what row was just tapped
            if let indexPath = tableView.indexPathForSelectedRow {
                
                let items = itemStore.allItems.filter{ item in showableFilter(item,indexPath.section) }
                
                if items.count > 0 {
                    let detailViewController = segue.destination as! DetailViewController
                    detailViewController.item = items[indexPath.row]
                    detailViewController.imageStore = imageStore
                }
            }
        default:
            preconditionFailure("Unexpected segue identifier")
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        switch identifier {
        case "showItem":
            if let indexPath = tableView.indexPathForSelectedRow {
                
                let items = itemStore.allItems.filter{ item in showableFilter(item,indexPath.section) }
                
                return items.count > 0
            } else {
                return false
            }
        default:
            preconditionFailure("Unexpected segue identifier")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    func getSectionOf(item :Item) -> Int {
        
        return item.valueInDollars > 50 ? moreThan50Section : otherSection
    }
}
