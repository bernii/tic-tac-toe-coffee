((exports) ->

    # ## Helper functions
    $ = (id) ->
        return document.getElementById(id)
    # Extend Array prototype with function
    # checking if secondArray is a part of current array
    Array::inArray = (secondArray) ->
        for arr in @
            isin = true
            for j in arr
                if secondArray.indexOf(j) == -1
                    isin = false
                    break
            if isin
                return true
        return false

    # Some constant vars
    # Possible game scores
    SCORE =
        WIN: 2
        LOOSE: -2
        DRAW: 1
    # Event types
    EVENT = 
        COMPUTER_MOVE: 1
        STATUS_CHANGE: 2
    # Current game status
    GAME_STATUS =
        START: 0
        PROGRESS: 1
        FINISH: 2

    # Tree structure definition to store NegaMax work and visualize it later
    class Node
        constructor: (@board) ->
            # XXXXXXXXXXXXXXXXXXXX
        hasChildren: () ->
            if @children.length != 0
                return true
            return false
        value: null
        children: []
        # Convert array to Node objects
        @arrayAsNodes: (arr) ->
            out = []
            for elem in arr
                out.push(new Node(elem))
            return out

    # Listener to handle notifications
    class Listener
        notify: (eventType, source) ->
            throw "NotImplemented";

    # User interface for board
    class BoardGUI extends Listener

        constructor: (@canvas, @board) ->
            @tickWidth = @canvas.width / 3
            @tickHeight = @canvas.height / 3
            @ctx = @canvas.getContext('2d')
        # Get index of the field containing x,y coordinates
        getIndex: (x, y) ->
            i = 0
            row = 0
            for state in @board.currentState
                if i != 0 and i % 3 == 0
                    row++
                if x > (i % 3) * @tickWidth and x < (i % 3) * @tickWidth + @tickWidth \
                        and y > row * @tickHeight and y < row * @tickHeight + @tickHeight
                    return i          
                i++
        # Redraw board on new computer move
        notify: (event, game) ->
            @board = game.getBoard()
            @draw()
        # Get field index on user click
        handleClick: (x, y) ->
            index = @getIndex(x, y)
            return index
        # Draw X's
        drawX: (centerX, centerY) ->
            @ctx.beginPath()
            len = if @tickWidth > @tickHeight then @tickHeight / 2 else @tickWidth / 2
            len *= 0.8
            @ctx.moveTo(centerX - len, centerY - len)
            @ctx.lineTo(centerX + len, centerY + len)
            @ctx.moveTo(centerX - len, centerY + len)
            @ctx.lineTo(centerX + len, centerY - len)
            @ctx.stroke()
            @ctx.closePath()
        # Draw O's
        drawO: (centerX, centerY) ->
            radius = if @tickWidth > @tickHeight then @tickHeight / 2 else @tickWidth / 2
            radius *= 0.8 # add some margin
            @ctx.beginPath()
            @ctx.arc(centerX, centerY, radius, 0 , 2 * Math.PI, false)
            @ctx.stroke()
            @ctx.closePath()
        # Draw checker board for Tic Tac Toe game
        draw: () ->
            @ctx.clearRect(0, 0, @canvas.width, @canvas.height)
            @ctx.strokeStyle = '#ffe400'
            @ctx.lineWidth   = 4

            ## Draw wireframe
            # rows
            for i in [0..1]
                @ctx.beginPath()
                @ctx.moveTo(0, (i + 1) * @tickHeight)
                @ctx.lineTo(3 * @tickWidth, (i + 1) * @tickHeight)
                @ctx.stroke()
                @ctx.closePath()
            # columns
            for i in [0..1]
                @ctx.beginPath()
                @ctx.moveTo((i + 1) * @tickWidth, 0)
                @ctx.lineTo((i + 1) * @tickWidth, 3 * @tickHeight)
                @ctx.stroke()
                @ctx.closePath()

            # Draw x's & y's according to board current state
            @ctx.strokeStyle = '#0f0' # green
            i = 0
            row = 0
            for state in @board.currentState
                if i != 0 and i % 3 == 0
                    row++
                if state == 1
                    @drawX((i % 3) * @tickWidth + @tickWidth/2, row * @tickHeight + @tickHeight/2)
                else if state == -1
                    @drawO((i % 3) * @tickWidth + @tickWidth/2, row * @tickHeight + @tickHeight/2)            
                i++

    # ## Represents Board and its current state
    # Current state is represented by an array of values
    # For example    would basically mean
    # [ 1,  0, -1,                         X |   | O
    #   0, -1,  0                         -----------
    #   0,  1,  0]                           | O |
    #                                     -----------
    #                                        | X |
    # 0 - free field, 1 - X on the field, -1 - O on the field
    #
    #
    class Board
        # Initialize board with default or custom state
        constructor: (state=null, @_winningIndexes) ->
            if state
                @currentState = state

            if not @_winningIndexes
                @_winningIndexes = @computeWinningIndexes()

        currentState: [0, 0, 0,
                       0, 0, 0,
                       0, 0, 0]

        # Possible moves are the ones with state == 0
        getPossibleMoves: () ->
            return @getIndexesWithValue(0)
        # Array with possible moves from current position
        getPossibleBoards: (moveType) ->
            boards = []
            for move in @getPossibleMoves()
                newBoard = @currentState[..]
                newBoard[move] = moveType
                board = new Board(newBoard, @_winningIndexes)
                board.move = move
                boards.push(board)
            return boards
        # Get field indexes with a value (-1, 0, 1)
        getIndexesWithValue: (value) ->
            indexes = []
            for index in [0..@currentState.length]
                if @currentState[index] == value
                    indexes.push(index)
            return indexes
        # Get score of current board state
        getScore: () ->
            indexesWin = @getIndexesWithValue(1)
            indexesLoose = @getIndexesWithValue(-1)

            isWin = @_winningIndexes.inArray(indexesWin)
            isLoose = @_winningIndexes.inArray(indexesLoose)

            if isWin
                return SCORE.WIN
            else if isLoose
                return SCORE.LOOSE
            else if @getIndexesWithValue(0).length == 0
                return SCORE.DRAW
            return null # game still in progress

        # Convert to a string
        toString: () ->
            str = ""
            for i in [0...@currentState.length]
                if (i % 3) == 0
                    str += "\n"
                strval = @currentState[i]
                if @currentState[i] >= 0
                    strval = " " + strval
                str += " " + strval
            return str

        # Compute winning combinations for current board (rows, cols, diagonals)
        # For 3x3 board return value should be: 
        # [[0,1,2], [3,4,5], [6,7,8], [0,3,6], [1,4,7], [2,5,8], [0,4,8], [2,4,6]]
        computeWinningIndexes: () ->
            boardWidth = boardHeight = Math.sqrt(@currentState.length)
            indexes = []
            
            # Get rows
            row = []
            for i in [0..boardWidth * boardHeight]
                if i % boardWidth == 0 and i != 0
                    indexes.push(row)
                    row = []
                row.push(i)

            # Get columns
            col = []
            for i in [0...boardWidth]
                for a in [0...boardWidth]
                    col.push(a * boardWidth + i)
                indexes.push(col)
                col = []

            # Get diagonals
            diag = []
            for i in [0...boardWidth]
                diag.push(i * boardWidth + i)
            if diag.length == boardWidth
                indexes.push(diag)
            diag = []
            for i in [0...boardWidth]
                diag.push((i + 1) * boardWidth - (i + 1))
            if diag.length == boardWidth
                indexes.push(diag)

            return indexes

        _winningIndexes: null
        
            
           
    class AiEngine

        # Get index of the next move that should be performed by AI Player
        getNextMove: (board) ->
            throw "NotImplemented";

    class NegaMaxEngine extends AiEngine
        cache: {}
        defaultDepth: 100

        # NegaMax depth-limited with alpha-beta pruning
        negamax: (node, depth=@defaultDepth, alfa=Number.NEGATIVE_INFINITY, beta=Number.POSITIVE_INFINITY, color=1) ->
            node.children = Node.arrayAsNodes(node.board.getPossibleBoards(color))
            score = node.board.getScore(color)

            # TODO: Use cache, dynamic programing FTW!
            # if @cache[node.board.currentState] != undefined and depth != @defaultDepth
            #     node.value = @cache[node.board.currentState]
            #     return node.value

            if node.children.length == 0 or depth == 0 or score != null
                node.score = color * score
                return node.score
            else
                for child in node.children
                    val = -@negamax(child, depth - 1, -beta, -alfa, -color)
                    if val >= beta
                        node.value = val
                        return val
                    alfa = Math.max(alfa, val)
                node.value = alfa
                return alfa

        getNextMove: (board) ->
            @root = new Node(board)
            @negamax(@root)
            for child in @root.children
                # Negamax computed way
                if child.value == -@root.value or child.score == -@root.value
                    return child.board.move
            return null

    # Dumb engine with random moves
    class RandomEngine extends AiEngine

        getNextMove: (board) ->
            indexes = board.getIndexesWithValue(0)
            return indexes[Math.floor(Math.random() * indexes.length)]

    # Hleper class for drawing NegaMax graph
    class Graph extends Listener

        constructor: (@negamax) ->

        numPerDepth: {1: 1}
        depthIndex: {}
        idd: 0

        count: (node, depth=1) ->
            val = node.value
            if "score" of node
                val = node.score

            if node.children.length != 0
                for child in node.children
                    @numPerDepth[depth + 1] =  (@numPerDepth[depth + 1] or 0) + 1
                    @count(child, depth + 1)

        print: (node, depth=1) ->
            if node.children.length != 0
                for child in node.children
                    @print(child, depth + 1)

            @depthIndex[depth] = (@depthIndex[depth] or 0) + 1

            id = [node.board.toString(), @idd++].join(" ")
            s1.addNode(id,
                'x': (300 / (@numPerDepth[depth] + 1)) * @depthIndex[depth]
                'y': depth * 10
                'size': 10/depth
                'color': '#ffaa00'
            )
            node.id = id
            if node.children.length != 0
                for child in node.children
                    s1.addEdge(@idd++, id, child.id)

        notify: (event, game) ->
            @board = game.getBoard()
            if game.aiEngine == aiEngines.negamax
                @draw()

        draw: () ->
            if not @negamax.root
                return
            @numPerDepth = {1: 1}
            @depthIndex = {}
            s1.emptyGraph()
            @count(@negamax.root)
            @print(@negamax.root)
            s1.draw()

    # Simple Listener/observer pattern
    class Event
        _listeners: []
        addListener: (event, element) ->
            @_listeners.push({event: event, element: element})

        notifyListeners: (event, value) ->
            for listener in @_listeners
                if listener.event == event
                    listener.element.notify({type: event, value: value}, @)
            return true

    # Main Game object
    class Game extends Event

        constructor: () ->
            @board = new Board
            @status = GAME_STATUS.START

        getBoard: () ->
            return @board

        setAi: (@aiEngine) ->

        restart: () ->
            @status = GAME_STATUS.START
            @notifyListeners(EVENT.STATUS_CHANGE, @status)
            @board.currentState = [0,0,0,0,0,0,0,0,0]
            @notifyListeners(EVENT.COMPUTER_MOVE)

        finish: () ->
            @status = GAME_STATUS.FINISH
            @notifyListeners(EVENT.STATUS_CHANGE, @status)
            @notifyListeners(EVENT.COMPUTER_MOVE)

        setPlayerMove: (index=null) ->
            if @status == GAME_STATUS.START
                @status = GAME_STATUS.PROGRESS
                @notifyListeners(EVENT.STATUS_CHANGE)
            if index != null
                if @board.currentState[index] == 0
                    @board.currentState[index] = -1
                else
                    # Do nothing, this is not a free field
                    return

            # Check score before computer move
            if @board.getScore() != null
                @finish()
                return

            indexAi = @aiEngine.getNextMove(@board)
            @board.currentState[indexAi] = 1 

            # Check score after computer move
            if @board.getScore() != null
                @finish()
                return

            @notifyListeners(EVENT.COMPUTER_MOVE)

    # Handle UI events and user interaction
    class AppUI extends Listener

        constructor: (@game) ->
            @start = $("computer-start")
            @restart = $("restart")
            @aiType = $("ai-type")
            avgrnd = document.getElementsByClassName('avgrund-popup')[0]
            @notifyTitle = avgrnd.getElementsByTagName("h2")[0]
            @notifyParagraphs = avgrnd.getElementsByTagName("p")

            $("btn-close").addEventListener('click', avgrund.deactivate, false)
            $("btn-restart").addEventListener('click', () =>
                avgrund.deactivate()
                @game.restart()
            , false)
        # Update UI on notification
        notify: (event, game) ->
            if event.value == GAME_STATUS.FINISH
                score = game.getBoard().getScore()
                @playerNotify(score)
                
            else if event.type == EVENT.STATUS_CHANGE
                if @restart.disabled
                    @restart.classList.remove("disabled")
                    @restart.removeAttribute("disabled")
                    @start.classList.add("disabled")
                    @start.disabled = "disabled"
                else
                    @start.classList.remove("disabled")
                    @start.removeAttribute("disabled")
                    @restart.classList.add("disabled")
                    @restart.disabled = "disabled"

        playerNotify: (type) ->
            if type == SCORE.LOOSE
                @notifyTitle.innerHTML = "You Win!"
                @notifyParagraphs[0].innerHTML = "Congratulations! You are the best!"
                @notifyParagraphs[1].innerHTML = "Cool, but now maybe try using the more advanced AI mode?"
            else if type == SCORE.WIN
                @notifyTitle.innerHTML = "You Loose :-("
                @notifyParagraphs[0].innerHTML = "We're sorry it looks that computer has beaten you.."
                @notifyParagraphs[1].innerHTML = "Better luck next time! Cheer up!"
            else if type == SCORE.DRAW
                @notifyTitle.innerHTML = "A Draw!"
                @notifyParagraphs[0].innerHTML = "This was pretty exciting huh?"
                @notifyParagraphs[1].innerHTML = "You can change computer AI mode if you find current oponent too hard to beat..."
            avgrund.activate('stack')

    init = () ->
        # Initialize sigma (graph lib)
        window.s1 = sigma.init(document.getElementById('sig')).drawingProperties(
            defaultLabelHoverColor: '#000'
        ).mouseProperties(
            mouseEnabled: false
        ).graphProperties(
            defaultLabelColor: '#fff'
        )

        # Create game and set the default AI
        game = new Game
        game.setAi(aiEngines.negamax)

        # Initialize graph and app user interface
        appUI = new AppUI(game)
        graph = new Graph(aiEngines.negamax)

        boardGUI = new BoardGUI($("tictactoe"), game.board)
        boardGUI.draw()

        # Register listeners
        game.addListener(EVENT.COMPUTER_MOVE, boardGUI)
        game.addListener(EVENT.COMPUTER_MOVE, graph)
        game.addListener(EVENT.STATUS_CHANGE, appUI)

        # Register click/change events
        tictac = $("tictactoe")

        tictacClick = (event) ->
            event = event || window.event
            x = event.pageX - tictac.offsetLeft
            y = event.pageY - tictac.offsetTop
            index = boardGUI.handleClick(x, y)
            game.setPlayerMove(index)

        startComputer = (event) ->
            game.setPlayerMove()

        restart = () ->
            game.restart()

        changeAi = (event) ->
            game.setAi(aiEngines[@value])

        $("computer-start").addEventListener('click', startComputer, false)
        $("restart").addEventListener('click', restart, false)
        $("ai-type").onchange = changeAi
        tictac.addEventListener('click', tictacClick, false)

    # Available AI engines
    aiEngines = 
        negamax: new NegaMaxEngine
        random: new RandomEngine

    # Make the exports!
    exports.init = init
    exports.aiEngines = aiEngines
    exports.Board = Board
    exports.NegaMaxEngine = NegaMaxEngine


)(if typeof exports == 'undefined' then this['main']={} else exports)
