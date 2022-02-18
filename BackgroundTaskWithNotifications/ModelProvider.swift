//
//  ModelProvider.swift
//  BackgroundTaskWithNotifications
//
//  Created by Jason Anderson on 2/18/22.
//

import Foundation
import CoreData

public final class ModelProvider {
    private let container = NSPersistentContainer(name: "NotificationsModel")
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    func performInBackground(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }
    
    func saveContext(_ context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        
        try? context.save()
    }
    
    init() {
        container.loadPersistentStores { description, error in
            if error == nil {
                var values = URLResourceValues()
                values.isExcludedFromBackup = true
                try? description.url?.setResourceValues(values)

                self.loadData()
            }
        }
    }
    
    private func loadData() {
        let isLoaded = UserDefaults.standard.bool(forKey: "DATA_LOADED")
        
        if !isLoaded {
            let decoder = JSONDecoder()
            guard let dataUrl = Bundle.main.url(forResource: "tiles", withExtension: "json"),
                  let data = try? Data(contentsOf: dataUrl),
                  let tiles = try? decoder.decode(TileData.self, from: data) else { return }
            
            for tile in tiles.tiles {
                print("tile \(tile.text)")
                
                _ = TileEntity(context: viewContext, item: tile)
            }
            
            do {
                try viewContext.save()
                UserDefaults.standard.set(true, forKey: "DATA_LOADED")
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
}

struct TileData: Decodable {
    struct TileItem: Decodable {
        let text: String
        let identifier: String
        
        enum CodingKeys: String, CodingKey {
            case text
            case identifier = "id"
        }
    }
    
    let tiles: [TileItem]
    
    enum CodingKeys: String, CodingKey {
        case tiles
    }
}

extension TileEntity {
    convenience init(context: NSManagedObjectContext, item: TileData.TileItem) {
        self.init(context: context)
        text = item.text
        identifier = item.identifier
    }
}

extension ActiveTileEntity {
    convenience init(context: NSManagedObjectContext, tile: TileEntity) {
        self.init(context: context)
        self.tile = tile
    }
}
