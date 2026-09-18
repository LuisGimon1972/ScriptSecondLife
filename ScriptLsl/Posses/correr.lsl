// Configuração do Script de Corrida (Run Script)
// Certifique-se de que a animação ("Correr" ou o nome exato dela) está no inventário do objeto/HUD.

string ANIMATION_RUN = "Correr"; // Substitua pelo nome exato da animação no inventário
integer PERMISSIONS_MASK = (PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS);

default
{
    state_entry()
    {
        // Solicita permissões necessárias ao dono do objeto
        llRequestPermissions(llGetOwner(), PERMISSIONS_MASK);
    }

    run_time_permissions(integer perm)
    {
        if ((perm & PERMISSIONS_MASK) == PERMISSIONS_MASK)
        {
            // Pega o controle das teclas de movimento (frente, trás, lados, giros)
            llTakeControls(CONTROL_FWD | CONTROL_BACK | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT, TRUE, FALSE);
            llOwnerSay("Script de corrida ativado com sucesso!");
        }
    }

    control(key id, integer level, integer edge)
    {
        // Verifica se a tecla de ir para frente (CONTROL_FWD) foi pressionada
        if (level & CONTROL_FWD)
        {
            // Para a animação padrão de andar do Second Life e inicia a de correr
            llStopAnimation("Walking");
            llStartAnimation(ANIMATION_RUN);
        }
        else if (edge & CONTROL_FWD)
        {
            // Quando a tecla de ir para frente for solta, para a animação de corrida
            llStopAnimation(ANIMATION_RUN);
        }
    }

    changed(integer change)
    {
        // Se o objeto mudar de dono ou for desequipado, limpa as permissões e para animações
        if (change & CHANGED_OWNER)
        {
            llResetScript();
        }
    }
}