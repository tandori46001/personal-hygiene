import XCTest

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
}
