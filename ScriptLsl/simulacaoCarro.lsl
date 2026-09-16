integer motor_ligado = FALSE;
integer marcha_atual = 1; // 1 = Neutro ou Ré, indicando o estado das marchas

default
{
    state_entry()
    {
        llOwnerSay("Carro pronto. Sente-se e pressione HOME para ligar o motor.");
        llSetStatus(STATUS_PHYSICS, FALSE);
    }

    touch_start(integer total_number)
    {
        key avatar = llDetectedKey(0);
        // Pede permissão para controlar o avatar e capturar teclas
        llRequestPermissions(avatar, PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION);
    }

    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TAKE_CONTROLS)
        {
            // Captura as setas direcionais e comandos de teclas especiais
            llTakeControls(CONTROL_FWD | CONTROL_BACK | CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT | CONTROL_UP | CONTROL_DOWN, TRUE, FALSE);
        }
    }

    control(key id, integer level, integer edge)
    {
        // Como o LSL mapeia certas teclas, usamos CONTROL_UP (Home equivalente em alguns HUDs ou Page Up) 
        // e CONTROL_DOWN para ligar/desligar se necessário, ou podemos usar comandos de chat para D e R.
        
        if (!motor_ligado) return; // Se o motor estiver desligado, não faz nada

        vector motor_dir = <0, 0, 0>;

        // Seta para cima / Frente
        if (level & CONTROL_FWD)
        {
            if (marcha_atual == 1) // Marcha à frente (D)
                motor_dir.x = 25.0;
            else if (marcha_atual == -1) // Marcha atrás (R)
                motor_dir.x = -15.0;
        }
        // Seta para baixo / Ré ou Freio
        else if (level & CONTROL_BACK)
        {
            motor_dir.x = -10.0;
        }

        // Aplica a força ao veículo físico
        llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, motor_dir);
    }

    listen(integer channel, string name, key id, string message)
    {
        message = llToLower(message);

        // Ligar com HOME (ou comando de chat caso prefira)
        if (message == "ligar")
        {
            motor_ligado = TRUE;
            llSetStatus(STATUS_PHYSICS, TRUE);
            llSetVehicleType(VEHICLE_TYPE_CAR);
            llOwnerSay("Motor ligado! Use as setas para dirigir.");
        }
        // Desligar com END
        else if (message == "desligar")
        {
            motor_ligado = FALSE;
            llSetStatus(STATUS_PHYSICS, FALSE);
            llOwnerSay("Motor desligado.");
        }
        // Marcha Para Frente (D)
        else if (message == "d")
        {
            marcha_atual = 1;
            llOwnerSay("Marcha: [D] - Frente engatada.");
        }
        // Marcha Atrás (R)
        else if (message == "r")
        {
            marcha_atual = -1;
            llOwnerSay("Marcha: [R] - Ré engatada.");
        }
    }

    on_rez(integer start_param)
    {
        llListen(0, "", llGetOwner(), "");
    }
}