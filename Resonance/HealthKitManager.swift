import HealthKit
import SwiftUI
import UIKit

// MARK: - Health Stress Level Enum (renamed to avoid conflict)
enum HealthStressLevel: String {
    case veryLow = "Very Low"
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    
    var color: Color {
        switch self {
        case .veryLow: return .green
        case .low: return .blue
        case .moderate: return .yellow
        case .high: return .red
        }
    }
}

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var todaysSteps: Int = 0
    @Published var currentHeartRate: Double = 0
    @Published var latestHRV: Double = 0
    @Published var sleepHours: Double = 0
    @Published var activeCalories: Int = 0
    @Published var restingHeartRate: Double = 0
    @Published var workoutMinutes: Int = 0
    
    // Health data types we want to read
    private var readTypes: Set<HKObjectType> {
        return Set([
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
            HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKQuantityType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!,
            HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKQuantityType.workoutType(),
            HKQuantityType.categoryType(forIdentifier: .mindfulSession)!
        ])
    }
    
    // Health data types we want to write (optional)
    private var writeTypes: Set<HKSampleType> {
        return Set([
            HKQuantityType.categoryType(forIdentifier: .mindfulSession)!,
            HKQuantityType.workoutType()
        ])
    }
    
    // MARK: - Authorization
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if success {
                    print("HealthKit authorization granted")
                    self.fetchAllHealthData()
                } else if let error = error {
                    print("HealthKit authorization failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Fetch All Health Data
    func fetchAllHealthData() {
        print("📱 FETCHING ALL HEALTH DATA at \(Date().formatted(date: .omitted, time: .standard))")
        print("📱 Device: \(UIDevice.current.name)")
        fetchTodaysSteps()
        fetchLatestHeartRate()
        fetchHRV()
        fetchSleepAnalysis()
        fetchActiveCalories()
        fetchRestingHeartRate()
        fetchWorkoutMinutes()
        
        // Also start observing for real-time updates
        startObservingHealthData()
    }
    
    // MARK: - Steps
    func fetchTodaysSteps() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("❌ Failed to fetch steps: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            print("✅ STEPS TODAY: \(steps)")
            
            DispatchQueue.main.async {
                self.todaysSteps = steps
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Heart Rate
    func fetchLatestHeartRate() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        // Get heart rate from last 24 hours
        let endDate = Date()
        let startDate = Date(timeIntervalSinceNow: -86400) // 24 hours ago
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 5, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else {
                print("❌ No heart rate data in last 24 hours")
                return
            }
            
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            
            // Get the most recent reading
            if let mostRecent = samples.first {
                let heartRate = mostRecent.quantity.doubleValue(for: heartRateUnit)
                let timeAgo = Date().timeIntervalSince(mostRecent.startDate)
                let minutes = Int(timeAgo / 60)
                
                print("✅ HEART RATE: \(heartRate) bpm (from \(minutes) minutes ago)")
                print("   Source: \(mostRecent.sourceRevision.source.name)")
                
                DispatchQueue.main.async {
                    self.currentHeartRate = heartRate
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - HRV
    func fetchHRV() {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: 10, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else {
                print("No HRV data available")
                return
            }
            
            // Calculate average HRV from recent samples
            let hrvValues = samples.map { $0.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)) }
            let averageHRV = hrvValues.reduce(0, +) / Double(hrvValues.count)
            
            DispatchQueue.main.async {
                self.latestHRV = averageHRV
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Sleep
    func fetchSleepAnalysis() {
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 100, sortDescriptors: nil) { _, samples, error in
            guard let samples = samples as? [HKCategorySample] else {
                print("No sleep data available")
                return
            }
            
            // Calculate total sleep duration
            var totalSleepTime: TimeInterval = 0
            for sample in samples {
                if sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                    totalSleepTime += sample.endDate.timeIntervalSince(sample.startDate)
                }
            }
            
            DispatchQueue.main.async {
                self.sleepHours = totalSleepTime / 3600 // Convert to hours
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Active Calories
    func fetchActiveCalories() {
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch active calories")
                return
            }
            
            DispatchQueue.main.async {
                self.activeCalories = Int(sum.doubleValue(for: HKUnit.kilocalorie()))
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Resting Heart Rate
    func fetchRestingHeartRate() {
        let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: restingHRType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else {
                print("No resting heart rate data available")
                return
            }
            
            DispatchQueue.main.async {
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.restingHeartRate = sample.quantity.doubleValue(for: heartRateUnit)
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Workout Minutes
    func fetchWorkoutMinutes() {
        let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: exerciseType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch exercise minutes")
                return
            }
            
            DispatchQueue.main.async {
                self.workoutMinutes = Int(sum.doubleValue(for: HKUnit.minute()))
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Save Mindful Session
    func saveMindfulSession(duration: TimeInterval) {
        let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession)!
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-duration)
        
        let mindfulSample = HKCategorySample(type: mindfulType, value: 0, start: startDate, end: endDate)
        
        healthStore.save(mindfulSample) { success, error in
            if success {
                print("Mindful session saved successfully")
            } else if let error = error {
                print("Failed to save mindful session: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Real-time Monitoring
    func startObservingHealthData() {
        // Observe steps
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let stepQuery = HKObserverQuery(sampleType: stepType, predicate: nil) { _, completionHandler, error in
            if error == nil {
                print("📊 Steps updated - fetching new data")
                self.fetchTodaysSteps()
            }
            completionHandler()
        }
        healthStore.execute(stepQuery)
        
        // Observe heart rate
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let heartQuery = HKObserverQuery(sampleType: heartRateType, predicate: nil) { _, completionHandler, error in
            if error == nil {
                print("❤️ Heart rate updated - fetching new data")
                self.fetchLatestHeartRate()
            }
            completionHandler()
        }
        healthStore.execute(heartQuery)
        
        // Set up background delivery for continuous updates
        healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { success, error in
            if success {
                print("✅ Background delivery enabled for steps")
            }
        }
        
        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { success, error in
            if success {
                print("✅ Background delivery enabled for heart rate")
            }
        }
    }
    
    func startRealtimeHeartRateMonitoring() {
        startObservingHealthData()
    }
    
    // MARK: - Historical Data
    func fetchHistoricalData(days: Int) {
        print("📊 FETCHING HISTORICAL DATA for last \(days) days")
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
        
        // Fetch historical steps
        fetchHistoricalSteps(from: startDate, to: endDate)
        
        // Fetch historical heart rate
        fetchHistoricalHeartRate(from: startDate, to: endDate)
        
        // Fetch historical HRV
        fetchHistoricalHRV(from: startDate, to: endDate)
        
        // Fetch historical sleep
        fetchHistoricalSleep(from: startDate, to: endDate)
        
        // Fetch historical workouts
        fetchHistoricalWorkouts(from: startDate, to: endDate)
    }
    
    private func fetchHistoricalSteps(from startDate: Date, to endDate: Date) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: DateComponents(day: 1)
        )
        
        query.initialResultsHandler = { query, results, error in
            guard let results = results else {
                print("❌ Failed to fetch historical steps")
                return
            }
            
            results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let steps = Int(sum.doubleValue(for: HKUnit.count()))
                    let date = statistics.startDate
                    print("📅 Steps on \(date.formatted(date: .abbreviated, time: .omitted)): \(steps)")
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchHistoricalHeartRate(from startDate: Date, to endDate: Date) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(
            quantityType: heartRateType,
            quantitySamplePredicate: predicate,
            options: [.discreteAverage, .discreteMin, .discreteMax],
            anchorDate: startDate,
            intervalComponents: DateComponents(day: 1)
        )
        
        query.initialResultsHandler = { query, results, error in
            guard let results = results else { return }
            
            results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                if let avg = statistics.averageQuantity() {
                    let heartRate = avg.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                    print("📅 Avg HR on \(statistics.startDate.formatted(date: .abbreviated, time: .omitted)): \(Int(heartRate)) bpm")
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchHistoricalHRV(from startDate: Date, to endDate: Date) {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            guard let samples = samples as? [HKQuantitySample] else { return }
            
            // Group by day
            let grouped = Dictionary(grouping: samples) { sample in
                Calendar.current.startOfDay(for: sample.startDate)
            }
            
            for (date, daySamples) in grouped {
                let avgHRV = daySamples.map { $0.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)) }.reduce(0, +) / Double(daySamples.count)
                print("📅 Avg HRV on \(date.formatted(date: .abbreviated, time: .omitted)): \(Int(avgHRV)) ms")
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchHistoricalSleep(from startDate: Date, to endDate: Date) {
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            guard let samples = samples as? [HKCategorySample] else { return }
            
            // Group by night
            let grouped = Dictionary(grouping: samples) { sample in
                Calendar.current.startOfDay(for: sample.startDate)
            }
            
            for (date, nightSamples) in grouped {
                var totalSleepTime: TimeInterval = 0
                for sample in nightSamples {
                    if sample.value != HKCategoryValueSleepAnalysis.inBed.rawValue {
                        totalSleepTime += sample.endDate.timeIntervalSince(sample.startDate)
                    }
                }
                let hours = totalSleepTime / 3600
                if hours > 0 {
                    print("📅 Sleep on \(date.formatted(date: .abbreviated, time: .omitted)): \(String(format: "%.1f", hours)) hours")
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchHistoricalWorkouts(from startDate: Date, to endDate: Date) {
        let workoutType = HKWorkoutType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            guard let workouts = samples as? [HKWorkout] else { return }
            
            for workout in workouts {
                let duration = workout.duration / 60 // Convert to minutes
                let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                print("📅 Workout on \(workout.startDate.formatted(date: .abbreviated, time: .shortened)): \(Int(duration)) min, \(Int(calories)) cal")
            }
        }
        
        healthStore.execute(query)
    }
}

// MARK: - Stress Level Calculation
extension HealthKitManager {
    func calculateStressLevel() -> HealthStressLevel {
        // Simple stress calculation based on HRV and heart rate
        // Return moderate if no data available
        if latestHRV == 0 {
            return .moderate  // Default when no data
        }
        
        if latestHRV < 20 {
            return .high
        } else if latestHRV < 40 {
            return .moderate
        } else if latestHRV < 60 {
            return .low
        } else {
            return .veryLow
        }
    }
    
    func getEnergyLevel() -> Int {
        // Calculate energy based on sleep, HRV, and activity
        var energyScore = 50
        
        // Sleep factor
        if sleepHours >= 7 {
            energyScore += 20
        } else if sleepHours >= 6 {
            energyScore += 10
        }
        
        // HRV factor
        if latestHRV > 50 {
            energyScore += 15
        } else if latestHRV > 30 {
            energyScore += 5
        }
        
        // Activity factor
        if todaysSteps > 8000 {
            energyScore += 15
        } else if todaysSteps > 5000 {
            energyScore += 10
        }
        
        return min(100, max(0, energyScore))
    }
}