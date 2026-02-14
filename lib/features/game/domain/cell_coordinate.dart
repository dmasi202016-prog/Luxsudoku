class CellCoordinate {
  const CellCoordinate(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CellCoordinate && other.row == row && other.col == col;
  }

  @override
  int get hashCode => Object.hash(row, col);
}
