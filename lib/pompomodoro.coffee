PompomodoroView = require './pompomodoro-view'
PomoBar = require './status-bar-view'
{CompositeDisposable} = require 'atom'

module.exports = Pompomodoro =

  config:
    breakLength:
      description: 'Length of break in minutes'
      type: 'integer'
      default: 1

    workIntervalLength:
      description: 'Length of work intervals in minutes'
      type: 'integer'
      default: 1

    numberOfIntervals:
      description: 'Number of work intervals in a session'
      type: 'integer'
      default: 4

  pompomodoroView: null
  modalPanel: null
  subscriptions: null
  noOfIntervals: null
  breakLength: null
  workTime: null

  pomoBar: null
  currentPom: 1
  statusBar: null
  min: 0
  sec: 0

  activate: (state) ->
    @pompomodoroView = new PompomodoroView(state.pompomodoroViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @pompomodoroView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'pompomodoro:start': => @start()
    @subscriptions.add atom.commands.add 'atom-workspace', 'pompomodoro:skip': => @skip()

    @noOfIntervals = atom.config.get('Pompomodoro.numberOfIntervals')
    @breakLength = atom.config.get('Pompomodoro.breakLength') * 1000 * 60
    @workTime = atom.config.get('Pompomodoro.workIntervalLength') * 1000 * 60

  consumeStatusBar: (statusBar) ->
    @statusBar = statusBar
    @pomoBar = new PomoBar([@min,@sec], [@currentPom,@noOfIntervals])
    @statusBarTile1 = statusBar.addRightTile(item: @pomoBar.getTimer(), priority: 101)
    @statusBarTile2 = statusBar.addRightTile(item: @pomoBar.getElement(), priority: 100)

  break: (i) ->
    if i < this.noOfIntervals
      @modalPanel.show()
      document.onkeypress = -> false
    else
      atom.notifications.addSuccess("Well done, you've finished your sprint!")

  work: ->
    this.hidePanel()
    setTimeout ( =>
      atom.notifications.addInfo("1 minute until your break!")
    ) , @workTime - 1000 * 60
    @startTime = new Date()
    this.ticker()

  ticker: ->
    clock = setInterval ( =>
      timeRemaining = (@workTime - (new Date() - @startTime))/1000
      @min = Math.floor(timeRemaining / 60)
      @sec = Math.floor(timeRemaining % 60)

      this.clearBar()

      @consumeStatusBar(@statusBar)

      clearInterval(clock) if timeRemaining < 1
    ) , 1000

  start: ->
    this.session(1)

  session: (i) ->
    this.work()
    setTimeout ( =>
      this.break(i)
      setTimeout ( =>
        if @currentPom < @noOfIntervals
          @currentPom++
          this.session(i+1)
      ) , @breakLength
    ) , @workTime

  hidePanel: ->
    @modalPanel.hide()
    document.onkeypress = -> true

  skip: ->
    this.hidePanel()

  clearBar: ->
    @statusBarTile1?.destroy()
    @statusBarTile1 = null
    @statusBarTile2?.destroy()
    @statusBarTile2 = null

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @pompomodoroView.destroy()
