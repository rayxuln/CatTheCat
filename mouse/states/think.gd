extends State



# override
func enter(agent, state_machine):
	agent.start_think()

# override
func tick(agent, state_machine:StateMachine, delta) -> void:
	pass

# override
func physics_tick(agent, state_machine, delta):
	pass

# override
func exit(agent, state_machine):
	pass


