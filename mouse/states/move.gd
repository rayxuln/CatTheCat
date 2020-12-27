extends State



# override
func enter(agent, state_machine):
	agent.start_move()
	agent.modulate = Color.red

# override
func tick(agent, state_machine:StateMachine, delta) -> void:
	pass

# override
func physics_tick(agent, state_machine, delta):
	agent.move()

# override
func exit(agent, state_machine):
	agent.modulate = Color.white


