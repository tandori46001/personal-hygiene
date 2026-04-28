import Foundation

/// Round-23 slice T4.21: pure helper that re-stamps every block's category
/// in `blocks` to `newCategory`. Returns the mutated blocks; caller is
/// responsible for persisting via the routine repository.
public enum BulkCategoryEditor {

    public static func apply(
        category newCategory: BlockCategory,
        to blocks: [Block]
    ) -> [Block] {
        for block in blocks {
            block.category = newCategory
        }
        return blocks
    }
}
