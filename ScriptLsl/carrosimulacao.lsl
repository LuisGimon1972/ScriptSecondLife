integer motor_ligado = FALSE;
integer marcha = 1; // 1 para Frente (D), -1 para Ré (R)

default
{
    state_entry()
    {
        llOwnerSay("Carro estacionado. Sente-se nele e digite 'ligar' para dar partida.");
        llSetStatus(STATUS_PHYSICS, FALSE); // Começa desligado e travado no lugar
    }

    touch_start(integer total_number)
    {
        // Pede permissão ao avatar que sentou
        key avatar = llDetectedKey(0);
        llRequestPermissions(avatar, PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION);
    }

    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TAKE_CONTROLS)
        {
            // Libera o uso das setas direcionais do teclado
            llTakeControls(CONTROL_FWD | CONTROL_BACK | CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT, TRUE, FALSE);
        }
    }

    control(key id, integer level, integer edge)
    {
        if (!motor_ligado) return; // Se o motor estiver desligado, não faz nada

        vector forca_motor = <0, 0, 0>;
        vector forca_giro = <0, 0, 0>;

        // Aceleração (Seta para cima)
        if (level & CONTROL_FWD)
        {
            // Multiplica pela marcha atual (1 para frente, -1 para ré)
            forca_motor.x = 22.0 * (float)marcha;
        }
        // Freio / Ré rápida (Seta para baixo)
        else if (level & CONTROL_BACK)
        {
            forca_motor.x = -10.0;
        }

        // Direção (Setas Esquerda e Direita)
        if (level & CONTROL_ROT_LEFT)
        {
            forca_giro.z = 2.5; // Gira para a esquerda
        }
        else if (level & CONTROL_ROT_RIGHT)
        {
            forca_giro.z = -2.5; // Gira para a direita
        }

        // Aplica os parâmetros físicos ao veículo
        llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, forca_motor);
        llSetVehicleVectorParam(VEHICLE_ANGULAR_MOTOR_DIRECTION, forca_giro);
    }

    listen(integer channel, string name, key id, string message)
    {
        message = llToLower(message);

        if (message == "ligar")
        {
            motor_ligado = TRUE;
            llSetStatus(STATUS_PHYSICS, TRUE);
            llSetVehicleType(VEHICLE_TYPE_CAR);
            llOwnerSay("🚗 Motor LIGADO! Use as setas para guiar.");
        }
        else if (message == "desligar")
        {
            motor_ligado = FALSE;
            llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <0,0,0>);
            llSetStatus(STATUS_PHYSICS, FALSE);
            llOwnerSay("🛑 Motor DESLIGADO.");
        }
        else if (message == "d")
        {
            marcha = 1;
            llOwnerSay("⚙️ Marcha engatada: [D] (Frente)");
        }
        else if (message == "r")
        {
            marcha = -1;
            llOwnerSay("⚙️ Marcha engatada: [R] (Ré)");
        }
    }

    on_rez(integer start_param)
    {
        // Escuta comandos do dono no chat local (Canal 0)
        llListen(0, "", llGetOwner(), "");
    }
}