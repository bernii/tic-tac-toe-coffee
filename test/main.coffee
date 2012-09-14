'use strict';

arrays_equal = (a,b) -> return not (a<b or b<a)

module.exports =  (t, a) ->
    board = new t.Board;

    # Indexes compute
    winningIndexes3x3 = [[0,1,2], [3,4,5], [6,7,8], [0,3,6], [1,4,7], [2,5,8], [0,4,8], [2,4,6]]
    winningIndexes = board.computeWinningIndexes()

    findIndexes = (needles, haystack) ->
        for x in [0...needles.length]
            found = false
            for i in [0...haystack.length]
                if arrays_equal(haystack[i], needles[x])
                    found = true
                    break
            a.ok(found, "Error computing winning indexes, missing " + needles[x])

    findIndexes(winningIndexes3x3, winningIndexes)

    # 4x4 board text
    winningIndexes4x4 = [[0,1,2,3], [4,5,6,7], [0,4,8,12]]
    board.currentState = [0, 0, 0, 0,
                          0, 0, 0, 0,
                          0, 0, 0, 0,
                          0, 0, 0, 0]
    winningIndexes = board.computeWinningIndexes()
    findIndexes(winningIndexes4x4, winningIndexes)

    # NegaMax
    aiEngine = new t.NegaMaxEngine
    testBoard = new t.Board([1,  1, 0,
                            -1, -1, 0,
                             0,  0, 1])
    indexAi = aiEngine.getNextMove(testBoard)
    a(indexAi, 2, "NegaMax next move computation")

    testBoard = new t.Board([1,  1, -1,
                            -1,  0, -1,
                             0,  0, 1])
    indexAi = aiEngine.getNextMove(testBoard)
    a(indexAi, 4, "NegaMax next move computation")

    return @
    