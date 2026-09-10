//O que o pequeno script dentro do "Prop" precisa ter:
//Coloque este trecho curto dentro do inventário do objeto prop (ex: dentro do copo de café) para que ele voe direto para a mão direita do avatar assim que for gerado:
//default
{
    on_rez(integer start_param)
    {
        if (start_param == 99)
        {
            llRequestPermissions(llGetOwner(), PERMISSION_ATTACH);
        }
    }

    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_ATTACH)
        {
            // Anexa automaticamente na mão direita do avatar
            llAttachToAvatarTemp(ATTACH_R_HAND);
        }
    }
    
    detach(key id)
    {
        if (id == NULL_KEY)
        {
            llDie(); // Deleta o prop do mundo quando o usuário desataca ou levanta
        }
    }
}
