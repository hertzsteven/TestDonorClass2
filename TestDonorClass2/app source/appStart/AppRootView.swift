//
//  AppRootView.swift
//  TestDonorClass2
//
//  Created by Steven Hertz on 5/2/25.
//


import SwiftUI

struct AppRootView: View {
  // 1️⃣ Declare your StateObjects without initial value
  @StateObject private var donorObject: DonorObjectClass
  @StateObject private var donationObject: DonationObjectClass
  @StateObject private var campaignObject: CampaignObjectClass
  @StateObject private var incentiveObject: DonationIncentiveObjectClass
  @StateObject private var defaultSettingsVM: DefaultDonationSettingsViewModel

  init() {
    // 2️⃣ Create each instance (they’ll pull from DatabaseManager.shared internally)
    let donorObj       = try! DonorObjectClass()
    let donationObj    = try! DonationObjectClass()
    let campaignObj    = try! CampaignObjectClass()
    let incentiveObj   = try! DonationIncentiveObjectClass()
    let defaultSettings = DefaultDonationSettingsViewModel()

    // 3️⃣ Assign into the @StateObject wrappers
    _donorObject       = StateObject(wrappedValue: donorObj)
    _donationObject    = StateObject(wrappedValue: donationObj)
    _campaignObject    = StateObject(wrappedValue: campaignObj)
    _incentiveObject   = StateObject(wrappedValue: incentiveObj)
    _defaultSettingsVM = StateObject(wrappedValue: defaultSettings)
  }

  var body: some View {
//      Text("Hello, World!")
    LaunchScreenManager()
      .environmentObject(donorObject)
      .environmentObject(donationObject)
      .environmentObject(campaignObject)
      .environmentObject(incentiveObject)
      .environmentObject(defaultSettingsVM)
  }
}

#Preview {
    AppRootView()
}
