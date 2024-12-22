#!/bin/bash

user_file="users.txt"
grp_ajouter="grps.txt"
csv_file="users.csv"
archive_directory="/home/Archive"
gestion_user_log="GestionUser.log"
archivage_log="Archivage.log"

echo "1. Entrer comme admin"
read order

if [ "$order" == "1" ]; then

	echo "entrer votre mot de passe admin" 
	read password
	
	if [ "$password" == "admin" ]; then 
	        while true
	        do
	        echo
		echo "1. Ajouter un utilisateur"
		echo "2. Ajouter un groupe"
		echo "3. Voir les utilisateurs d'un groupe"
		echo "4. Pour supprimer un utilisateurs"
		echo "5. Pour supprimer un groupe et ces utilisateurs"
		echo "6. Pour ajout avec un fichier csv"
		echo "7. Pour suppression avec un fichier csv"
		echo "8. Gerer les archives"
		echo "9. Quit"
		read order2
		echo
		
		if [ "$order2" == "1" ]; then
		
			read -p "Enterer login du nouveau utilisateur: " login
			read -p "Entrer le mot de passe: " password
			read -p "Entrer le groupe: " groupe
			
			if grep -q "^$groupe:" /etc/group; then
			      echo "L'utilisateur $login a été ajouté au groupe $groupe"
			      echo "Login: $login, Password: $password, Groupe: $groupe" >> "$user_file"
			      echo "$login" >> $groupe.txt
			      echo "AU, $(date '+%Y-%m-%d %H:%M:%S'), $login, $groupe" >> "$gestion_user_log"
			      sudo useradd -m -p "$(openssl passwd -1 '$password')" -G "$groupe" "$login"
			else 
			      echo "Le groupe $groupe n'existe pas. Veuillez d'abord créer le groupe."
			      echo "AU, $(date '+%Y-%m-%d %H:%M:%S'), $login, $groupe (raison de l'erreur)" >> "$gestion_user_log"
			fi
			
		elif [ "$order2" == "2" ]; then
		        
		        read -p "Entrer le nom du groupe: " grp
	               	sudo groupadd "$grp"
		        echo "le groupe $grp a bien etait ajouter"
		        echo "Groupe : $grp" >> "$grp_ajouter"
		        echo "AG, $(date '+%Y-%m-%d %H:%M:%S'), $groupe" >> "$gestion_user_log"
		        touch $grp.txt
		        
		elif [ "$order2" == "3" ]; then 
		
		        echo "Liste des groupes"
		        cat "$grp_ajouter"
		        read -p "Entrer le nom du groupe" groupe
		        echo "les utilisateurs du $groupe"
		        getent group $groupe
		        
		elif [ "$order2" == "4" ]; then
		
		        cat $user_file
		        echo "Entrer le nom d'utilisateur a supprimer"
		        read nom 
		        sudo userdel $nom
		        grep -n "$nom" users.txt | cut -d ":" -f 1 | xargs -I {} sed -i '{}d' users.txt
		        echo "DU, $(date '+%Y-%m-%d %H:%M:%S'), $login, $groupe" >> "$gestion_user_log"
		        echo "l'utilisateur $nom a etait supprimer"
		        
		elif [ "$order2" == "5" ]; then
		
		        echo "Liste des groupes"
		        cat "$grp_ajouter"
		        echo "Entrer le nom du groupe a supprimer"
		        read nom
		        while read -r username; do
		            sudo userdel "$username"
		            grep -n "$username" $nom.txt | cut -d ":" -f 1 | xargs -I {} sed -i '{}d' $nom.txt
		        done < $nom.txt
		        sudo groupdel -f $nom
		        grep -n "$nom" grps.txt | cut -d ":" -f 1 | xargs -I {} sed -i '{}d' grps.txt
		        grep -n "$nom" users.txt | cut -d ":" -f 1 | xargs -I {} sed -i '{}d' users.txt
		        echo "DG, $(date '+%Y-%m-%d %H:%M:%S'), $groupe" >> "$gestion_user_log"
		        rm $nom.txt
		        
		elif [ "$order2" == "6" ]; then
		
		        echo "Debut ajout"
		        while IFS=',' read -r username password group
		        do
		          if [[ $username == "Username" ]]; then
		              continue
		          fi
		          sudo useradd -m "$username"
		          echo "$username:$password" | sudo chpasswd
		          sudo usermod -a -G "$group" "$username"
		          echo "User $username created with password $password and added to group $group"
		        done < "$csv_file"
		        echo "ajout complet"
		        
		elif [ "$order2" == "7" ]; then
		        
		      echo "Debut supression"
		      echo "Entrer le chemain du fichier CSV si c'est dans le meme dossier juste le nom:"
                      read csv_file
                      
		      while IFS=',' read -r username group
		      do
		       sudo userdel -r "$username"
		       sudo groupdel "$group"
		       echo "Deleted user: $username, group: $group"
		      done < "$csv_file" 
		      echo "Suppression complete"
		
		elif [ "$order2" == "8" ]; then
		     
		     echo "1. Archiver un repertoire unique"
		     echo "2. Archiver pleusieurs repertoire"
		     echo "3. Archiver a partir d'un fichier text"
		     read order3
		     
		          if [ "$order3" == "1" ]; then
		            
		             read -p "Enter the directory name to be archived: " source_directory
		             archive_name="$source_director.tar.gz"
		             full_source_directory="$(pwd)/$source_directory"
		             if [ -d "$full_source_directory" ]; then
		                tar -czf "$archive_directory/$archive_name" -C "$(dirname "$full_source_directory")" "$(basename "$full_source_directory")"
		                echo "Directory archived successfully."
		             else
		                echo "Error: Directory '$full_source_directory' does not exist."
		                exit 1
		             fi
		           
		           elif [ "$order3" == "2" ]; then
		           
		             read -p "Enter the directories to be archived (separer par espaces): " -a directories
		             for dir in "${directories[@]}"
		             do
		             if [ -d "$dir" ]; then
		                 archive_name="$(basename "$dir").tar.gz"
		                 archive_path="$archive_directory/$archive_name"
		                 tar -czf "$archive_path" -C "$(dirname "$dir")" "$(basename "$dir")"
		                 if [ $? -eq 0 ]; then
		                    echo "Successfully archived $dir"
		                 else
		                    echo "Failed to archive $dir"
		                 fi
		             else
		                 echo "Directory $dir does not exist"
		             fi
		             done
		          fi
		          
		          elif [ "$order3" == "3" ]; then
		             
		             read -p "Entrez le chemin vers le fichier texte : " file_path
		             if [ -f "$file_path" ]; then
		                 while IFS= read -r dir
		                 do
		                 if [ -d "$dir" ]; then
		                     archive_name="$(basename "$dir").tar.gz"
		                     archive_path="$archive_directory/$archive_name"
		                     tar -czf "$archive_path" -C "$(dirname "$dir")" "$(basename "$dir")"
		                     if [ $? -eq 0 ]; then
		                        echo "Répertoire $dir archivé avec succès"
		                     else
		                        echo "Échec de l'archivage du répertoire $dir"
		                     fi
		                 else
		                     echo "Le répertoire $dir n'existe pas"
		                 fi
		                 done < "$file_path"
		            else 
		                 echo "Le fichier $file_path n'existe pas"
		            fi
		             
		          
		elif [ "$order2" == "9" ]; then
		        
		        break
		        
		fi
		done
		
	else
        echo "mot de passe incorrect"
        fi
	fi