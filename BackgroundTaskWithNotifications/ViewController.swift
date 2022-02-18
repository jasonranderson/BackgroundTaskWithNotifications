//
//  ViewController.swift
//  BackgroundTaskWithNotifications
//
//  Created by Jason Anderson on 2/18/22.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let tableView = UITableView(frame: .zero)
    var tiles: [ActiveTileEntity] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CELL")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[table]|", options: [], metrics: nil, views: ["table": tableView]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[table]|", options: [], metrics: nil, views: ["table": tableView]))
        
        if let entityName = ActiveTileEntity.entity().name {
            tiles = (try? (UIApplication.shared.delegate as? AppDelegate)?.modelProvider.viewContext.fetch(NSFetchRequest(entityName: entityName)) as? [ActiveTileEntity]) ?? []
        }
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let retval = tableView.dequeueReusableCell(withIdentifier: "CELL", for: indexPath)
        
        let tile = tiles[indexPath.row]
        retval.textLabel?.text = tile.tile?.text
        
        return retval
    }
}

