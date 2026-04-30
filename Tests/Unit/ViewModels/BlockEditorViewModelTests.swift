@preconcurrency import XCTest

@testable import PersonalHygiene

@MainActor
final class BlockEditorViewModelTests: XCTestCase {

    func test_isValid_falseWhenTitleEmpty() {
        let vm = BlockEditorViewModel()
        XCTAssertFalse(vm.isValid)
    }

    func test_isValid_falseWhenTitleOnlyWhitespace() {
        let vm = BlockEditorViewModel()
        vm.title = "   "
        XCTAssertFalse(vm.isValid)
    }

    func test_isValid_trueWithSensibleDefaults() {
        let vm = BlockEditorViewModel()
        vm.title = "Aseo"
        XCTAssertTrue(vm.isValid)
    }

    func test_isValid_falseWhenDurationZero() {
        let vm = BlockEditorViewModel()
        vm.title = "Aseo"
        vm.durationMinutes = 0
        XCTAssertFalse(vm.isValid)
    }

    func test_isValid_falseWhenStartHourOutOfRange() {
        let vm = BlockEditorViewModel()
        vm.title = "Aseo"
        vm.startHour = 24
        XCTAssertFalse(vm.isValid)
    }

    func test_initEditing_populatesAllFields() {
        let block = Block(
            title: "Medicación",
            category: .medication,
            startMinutesFromMidnight: 8 * 60 + 30,
            durationMinutes: 5,
            notes: "Con agua",
            notificationLeadMinutes: 5,
            isDeepFocus: true
        )
        let vm = BlockEditorViewModel(editing: block)

        XCTAssertEqual(vm.title, "Medicación")
        XCTAssertEqual(vm.category, .medication)
        XCTAssertEqual(vm.startHour, 8)
        XCTAssertEqual(vm.startMinute, 30)
        XCTAssertEqual(vm.durationMinutes, 5)
        XCTAssertEqual(vm.notes, "Con agua")
        XCTAssertEqual(vm.notificationLeadMinutes, 5)
        XCTAssertTrue(vm.isDeepFocus)
        XCTAssertEqual(vm.editingBlockID, block.id)
    }

    func test_snapshot_returnsBlockMatchingFormState() {
        let vm = BlockEditorViewModel()
        vm.title = "  Aseo  "
        vm.category = .hygiene
        vm.startHour = 7
        vm.startMinute = 15
        vm.durationMinutes = 25
        vm.notes = "Cepillarse bien"
        vm.notificationLeadMinutes = 10
        vm.isDeepFocus = false

        let block = vm.snapshot()
        XCTAssertEqual(block.title, "Aseo")
        XCTAssertEqual(block.startMinutesFromMidnight, 7 * 60 + 15)
        XCTAssertEqual(block.durationMinutes, 25)
        XCTAssertEqual(block.notes, "Cepillarse bien")
    }

    func test_apply_updatesExistingBlockInPlace() {
        let block = Block(
            title: "Old",
            category: .meal,
            startMinutesFromMidnight: 0,
            durationMinutes: 30
        )
        let vm = BlockEditorViewModel(editing: block)
        vm.title = "New"
        vm.startHour = 9
        vm.startMinute = 0
        vm.durationMinutes = 45

        vm.apply(to: block)

        XCTAssertEqual(block.title, "New")
        XCTAssertEqual(block.startMinutesFromMidnight, 9 * 60)
        XCTAssertEqual(block.durationMinutes, 45)
    }

    func test_parsedLocation_nilWhenBothEmpty() {
        let vm = BlockEditorViewModel()
        vm.title = "x"
        XCTAssertNil(vm.parsedLocation)
        XCTAssertTrue(vm.isLocationValid)
    }

    func test_parsedLocation_returnsCoordinatesWhenValid() {
        let vm = BlockEditorViewModel()
        vm.title = "Dentist"
        vm.locationName = "Clinic"
        vm.latitudeText = "40.4168"
        vm.longitudeText = "-3.7038"
        XCTAssertEqual(vm.parsedLocation?.latitude, 40.4168)
        XCTAssertEqual(vm.parsedLocation?.longitude, -3.7038)
        XCTAssertEqual(vm.parsedLocation?.displayName, "Clinic")
        XCTAssertTrue(vm.isLocationValid)
    }

    func test_parsedLocation_acceptsCommaDecimal() {
        let vm = BlockEditorViewModel()
        vm.title = "x"
        vm.latitudeText = "40,4168"
        vm.longitudeText = "-3,7038"
        XCTAssertNotNil(vm.parsedLocation)
    }

    func test_isLocationValid_falseWhenPartial() {
        let vm = BlockEditorViewModel()
        vm.title = "x"
        vm.latitudeText = "40.4168"
        XCTAssertFalse(vm.isLocationValid)
        XCTAssertFalse(vm.isValid)
    }

    func test_isLocationValid_falseWhenOutOfRange() {
        let vm = BlockEditorViewModel()
        vm.title = "x"
        vm.latitudeText = "200"
        vm.longitudeText = "-500"
        XCTAssertFalse(vm.isLocationValid)
    }

    func test_snapshot_writesLocationFieldsToBlock() {
        let vm = BlockEditorViewModel()
        vm.title = "Dentist"
        vm.locationName = "Clinic"
        vm.latitudeText = "40.4168"
        vm.longitudeText = "-3.7038"

        let block = vm.snapshot()
        XCTAssertEqual(block.latitude, 40.4168)
        XCTAssertEqual(block.longitude, -3.7038)
        XCTAssertEqual(block.locationName, "Clinic")
    }

    func test_hasUnsavedChanges_falseAfterInit() {
        let vm = BlockEditorViewModel()
        XCTAssertFalse(vm.hasUnsavedChanges)
    }

    func test_hasUnsavedChanges_trueAfterTitleEdit() {
        let vm = BlockEditorViewModel()
        vm.title = "Aseo"
        XCTAssertTrue(vm.hasUnsavedChanges)
    }

    func test_hasUnsavedChanges_falseAfterTypeAndDelete() {
        let vm = BlockEditorViewModel()
        vm.title = "tmp"
        vm.title = ""
        XCTAssertFalse(vm.hasUnsavedChanges, "typing then deleting back to initial counts as 'no change'")
    }

    func test_hasUnsavedChanges_falseAfterEditingInitWithMatchingFields() {
        let block = Block(title: "Pill", category: .medication, startMinutesFromMidnight: 8 * 60, durationMinutes: 5)
        let vm = BlockEditorViewModel(editing: block)
        XCTAssertFalse(vm.hasUnsavedChanges)
    }

    func test_hasUnsavedChanges_trueWhenAnyFieldDiverges() {
        let block = Block(title: "Pill", category: .medication, startMinutesFromMidnight: 8 * 60, durationMinutes: 5)
        let vm = BlockEditorViewModel(editing: block)
        vm.notificationLeadMinutes += 5
        XCTAssertTrue(vm.hasUnsavedChanges)
    }

    func test_apply_clearsLocationWhenFieldsEmpty() {
        let block = Block(
            title: "Dentist",
            category: .medical,
            startMinutesFromMidnight: 10 * 60,
            durationMinutes: 30,
            location: BlockLocation(latitude: 40.4168, longitude: -3.7038, displayName: "Clinic")
        )
        let vm = BlockEditorViewModel(editing: block)
        vm.latitudeText = ""
        vm.longitudeText = ""
        vm.locationName = ""

        vm.apply(to: block)
        XCTAssertNil(block.location)
        XCTAssertNil(block.latitude)
        XCTAssertNil(block.longitude)
        XCTAssertNil(block.locationName)
    }

    // MARK: - Round-26: smart default start time (carry-over from session 23)

    func test_nextAvailableStart_emptyTemplate_returns_7AM() {
        XCTAssertEqual(BlockEditorViewModel.nextAvailableStart(after: []), 7 * 60)
    }

    func test_nextAvailableStart_singleBlock_returns_endPlus5() {
        let block = Block(
            title: "Cafe",
            category: .meal,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 15
        )
        XCTAssertEqual(
            BlockEditorViewModel.nextAvailableStart(after: [block]),
            7 * 60 + 15 + 5
        )
    }

    func test_nextAvailableStart_picksLatestEnding_notFirst() {
        let early = Block(
            title: "Cafe",
            category: .meal,
            startMinutesFromMidnight: 7 * 60,
            durationMinutes: 15
        )
        let late = Block(
            title: "Teletravail",
            category: .work,
            startMinutesFromMidnight: 9 * 60,
            durationMinutes: 90
        )
        XCTAssertEqual(
            BlockEditorViewModel.nextAvailableStart(after: [early, late]),
            10 * 60 + 30 + 5
        )
    }

    func test_nextAvailableStart_clamps_to_2355() {
        let lateBlock = Block(
            title: "Late",
            category: .work,
            startMinutesFromMidnight: 23 * 60 + 30,
            durationMinutes: 60
        )
        XCTAssertEqual(
            BlockEditorViewModel.nextAvailableStart(after: [lateBlock]),
            23 * 60 + 55
        )
    }

    func test_initWithDefault_setsStartHourAndMinute() {
        let vm = BlockEditorViewModel(defaultStartMinutesFromMidnight: 9 * 60 + 35)
        XCTAssertEqual(vm.startHour, 9)
        XCTAssertEqual(vm.startMinute, 35)
        // hasUnsavedChanges == false proves the initial-state baseline
        // was overwritten alongside the live values.
        XCTAssertFalse(vm.hasUnsavedChanges)
    }

    func test_initWithDefault_clamps_outOfRange() {
        let belowZero = BlockEditorViewModel(defaultStartMinutesFromMidnight: -100)
        XCTAssertEqual(belowZero.startHour, 0)
        XCTAssertEqual(belowZero.startMinute, 0)

        let beyondDay = BlockEditorViewModel(defaultStartMinutesFromMidnight: 25 * 60)
        XCTAssertEqual(beyondDay.startHour, 23)
        XCTAssertEqual(beyondDay.startMinute, 59)
    }
}
