// Configurações iniciais
string DEFAULT_ANIMATION = "sit_relaxado"; // Nome da animação no inventário do objeto
integer DIALOG_CHANNEL = -4839201;
integer listener;

default
{
    state_entry()
    {
        // Define o texto que aparece ao passar o mouse na cadeira
        llSetClickAction(CLICK_ACTION_SIT);
        llSetSitText("Sentar Estiloso");
        
        // Define o ponto exato onde o avatar senta (Posição x, y, z e Rotação)
        llSitTarget(<0.0, 0.0, 0.4>, ZERO_ROTATION);
    }

    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            key avatar = llAvatarOnSitTarget();
            
            if (avatar != NULL_KEY)
            {
                // Alguém sentou
                llRequestPermissions(avatar, PERMISSION_TRIGGER_ANIMATION);
                
                // Abre o canal de comunicação para o menu
                listener = llListen(DIALOG_CHANNEL, "", avatar, "");
                
                // Exibe um menu interativo para o usuário
                llDialog(avatar, "\nEscolha uma opção para sua postura:", ["Ajustar", "Mudar Pose", "Levantar"], DIALOG_CHANNEL);
            }
            else
            {
                // Alguém levantou
                key lastAvatar = llGetPermissionsKey();
                if (lastAvatar != NULL_KEY)
                {
                    llStopAnimation(DEFAULT_ANIMATION);
                }
                llListenRemove(listener);
                llReleaseCamera();
            }
        }
    }

    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            // Para a animação padrão do Second Life e toca a personalizada
            llStopAnimation("sit");
            llStartAnimation(DEFAULT_ANIMATION);
            
            // Permite que o avatar controle um pouco a câmera ao sentar
            llSetCameraAtOffset(<1.0, 0.0, 1.0>);
            llSetCameraEyeOffset(<-2.0, 0.0, 1.5>);
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if (message == "Levantar")
        {
            // Força o avatar a levantar
            llUnSit(id);
        }
        else if (message == "Mudar Pose")
        {
            // Aqui você alternaria para outra animação armazenada no inventário
            llOwnerSay("Função para alternar entre várias poses na mesma cadeira!");
            llDialog(id, "Escolha a nova pose:", ["Pose 1", "Pose 2", "Voltar"], DIALOG_CHANNEL);
        }
        else if (message == "Ajustar")
        {
            llOwnerSay("Use as ferramentas de ajuste do seu visualizador para refinar a posição se necessário.");
        }
    }
}