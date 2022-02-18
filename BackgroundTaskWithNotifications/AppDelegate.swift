//
//  AppDelegate.swift
//  BackgroundTaskWithNotifications
//
//  Created by Jason Anderson on 2/18/22.
//

import UIKit
import BackgroundTasks
import CoreData

let identifier: String = "com.kosoku.BackgroundTaskWithNotifications.tileAssignment"

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    let modelProvider = ModelProvider()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
        
        print("register for task")
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            self.handleTileAssignment(task: task as! BGAppRefreshTask)
        }
        
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(.banner)
    }

    func scheduleTileAssignment() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 60)
        
        do {
            print("schedule tile assignment")
            try BGTaskScheduler.shared.submit(request)
        } catch let error {
            print("task not scheduled \(error.localizedDescription)")
        }
    }
    
    /**
     To test, only works on device, not simulator
     1. run the app and send to background
     2. bring back to foreground and pause the app with debugger
     3. enter this in console to trigger task:
     
     e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.kosoku.BackgroundTaskWithNotifications.tileAssignment"]
     */
    func handleTileAssignment(task: BGAppRefreshTask) {
        print("handle tile assignment")
        if let entityName = TileEntity.entity().name, let tiles = try? modelProvider.viewContext.fetch(NSFetchRequest(entityName: entityName)) {
            
            let inactiveTiles = tiles.filter { ($0 as? TileEntity)?.activeTile == nil }
            print("inactive tiles \(inactiveTiles)")
            guard let scheduledTile = inactiveTiles.randomElement() as? TileEntity else {
                print("tile not selected, returning early")
                return
            }
            
            _ = ActiveTileEntity(context: modelProvider.viewContext, tile: scheduledTile)
            
            do {
                try modelProvider.viewContext.save()
                
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    if settings.authorizationStatus == .authorized {
                        let content = UNMutableNotificationContent()
                        content.title = "New Tile Activiated"
                        content.subtitle = scheduledTile.text ?? ""
                        content.sound = UNNotificationSound.default
                        
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                        let request = UNNotificationRequest(identifier: scheduledTile.identifier ?? UUID().uuidString, content: content, trigger: trigger)
                        
                        UNUserNotificationCenter.current().add(request)
                    }
                }
            } catch let error {
                print(error.localizedDescription)
                task.setTaskCompleted(success: false)
            }
        }
        
        task.setTaskCompleted(success: true)
        scheduleTileAssignment()
    }
}

