//
//  ReadingTable.swift
//  books
//
//  Created by Andrew Bennet on 16/10/2016.
//  Copyright © 2016 Andrew Bennet. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class ReadingTable: BookTable {

    override var navigationItemTitle: String {
        get { return "To Read" }
    }
    
    override func viewDidLoad() {
        readStates = [.toRead, .reading]
        super.viewDidLoad()
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Disable reorderng when searching, or when the sort order is not by date
        guard !resultsFilterer.showingSearchResults else { return false }
        guard UserSettings.tableSortOrder == .byDate else { return false }
        guard let toReadSectionIndex = sectionIndex(forReadState: .toRead) else { return false }

        // We can reorder the "ToRead" books if there are more than one
        return indexPath.section == toReadSectionIndex && self.tableView(tableView, numberOfRowsInSection: toReadSectionIndex) > 1
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section == proposedDestinationIndexPath.section {
            return proposedDestinationIndexPath
        }
        else {
            return IndexPath(row: 0, section: sectionIndex(forReadState: .toRead)!)
        }
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        // We should only have movement in the ToRead secion. We also ignore moves which have no effect
        guard let toReadSectionIndex = sectionIndex(forReadState: .toRead) else { return }
        guard sourceIndexPath.section == toReadSectionIndex && destinationIndexPath.section == toReadSectionIndex else { return }
        guard sourceIndexPath.row != destinationIndexPath.row else { return }
        
        // Calculate the ordering of the two rows involved
        let itemWasMovedDown = sourceIndexPath.row < destinationIndexPath.row
        let topRow = itemWasMovedDown ? sourceIndexPath.row : destinationIndexPath.row
        let bottomRow = itemWasMovedDown ? destinationIndexPath.row : sourceIndexPath.row
        
        // Move the objects to reflect the rows
        var objectsInSection = resultsController.sections![toReadSectionIndex].objects!
        let movedObj = objectsInSection.remove(at: sourceIndexPath.row)
        objectsInSection.insert(movedObj, at: destinationIndexPath.row)
        
        // Update the model sort indexes. The lowest sort number should be the sort of the book immediately
        // above the range, plus 1, or - if the range starts at the top - 0.
        var sortIndex: Int
        if topRow == 0 {
            sortIndex = 0
        }
        else {
            sortIndex = (objectsInSection[topRow - 1] as! Book).sort!.intValue + 1
        }
        for rowNumber in topRow...bottomRow {
            let book = objectsInSection[rowNumber] as! Book
            book.sort = NSNumber(integerLiteral: sortIndex)
            sortIndex += 1
        }
        
        // Turn off updates while we save the object context
        tableUpdater.withoutUpdates {
            if appDelegate.booksStore.save() {
                do {
                    try resultsController.performFetch()
                }
                catch {
                    // If the fetch failed and the cells are not in the position which the result controller thinks
                    // they are, refresh the table. This will put the cells back where they "should" be.
                    tableView.reloadData()
                }
            }
            else {
                // If the save failed, revert the cells
                tableView.reloadData()
            }
        }
    }
    
    @available(iOS 11.0, *)
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var actions = [UIContextualAction]()
        if let superConfiguration = super.tableView(tableView, leadingSwipeActionsConfigurationForRowAt: indexPath) {
            actions.append(contentsOf: superConfiguration.actions)
        }
        
        let readStateOfSection = readStateForSection(indexPath.section)
        let leadingSwipeAction = UIContextualAction(style: .normal, title: readStateOfSection == .toRead ? "Start" : "Finish") { [unowned self] _,_,callback in
            let book = self.resultsController.object(at: indexPath)
            if readStateOfSection == .toRead {
                book.transistionToReading()
            }
            else {
                book.transistionToFinished()
            }
            callback(true)
        }
        leadingSwipeAction.backgroundColor = readStateOfSection == .toRead ? UIColor.buttonBlue : UIColor.flatGreen
        leadingSwipeAction.image = readStateOfSection == .toRead ? #imageLiteral(resourceName: "Play") : #imageLiteral(resourceName: "Complete")
        actions.insert(leadingSwipeAction, at: 0)
        
        let configuration = UISwipeActionsConfiguration(actions: actions)
        configuration.performsFirstActionWithFullSwipe = true
        
        return configuration
    }

    override func footerText() -> String? {
        var footerPieces = [String]()
        if let toReadSectionIndex = self.sectionIndex(forReadState: .toRead) {
            let toReadCount = tableView(tableView, numberOfRowsInSection: toReadSectionIndex)
            footerPieces.append("To Read: \(toReadCount) book\(toReadCount == 1 ? "" : "s")")
        }
        
        if let readingSectionIndex = self.sectionIndex(forReadState: .reading) {
            let readingCount = tableView(tableView, numberOfRowsInSection: readingSectionIndex)
            footerPieces.append("Reading: \(readingCount) book\(readingCount == 1 ? "" : "s")")
        }

        guard footerPieces.count != 0 else { return nil }
        return footerPieces.joined(separator: "\n")
    }
}
