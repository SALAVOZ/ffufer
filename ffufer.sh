#!/bin/bash 
host=$1
dir_wordlist=$2
services=()
nmap_output=$(nmap -Pn -p80,443 $1 | grep "open")
if [[ $nmap_output == *"https"* ]]; then
        echo "Https Found"
        services+=("https")
fi
if [[ $nmap_output == *"http"* ]]; then
        echo "Http Found"
        services+=("http")
fi
for serv in ${services[@]}; do
        dir_list=("/")
        list=(["1"]="_")
        index=0
        while [[ ${#list[@]} -ne 0 ]]; do
                for url in ${list[@]}; do
                        current_url_to_delete_from_list=$url
                        echo "to fuzz"
                        for i in ${list[@]}; do
                                echo "$i" | tr "_" "/"
                        done
                        file_name=$(echo "$host""$url" | tr "/" "_")
                        url_input=$(echo $url | tr "_" "/")
                        ffuf -u "$serv""://$host""$url_input""FUZZ" -w $dir_wordlist -t 40  -o "$file_name" -of csv
                        while IFS= read -r line; do
                                if [[ $line == *"FUZZ"* ]]; then
                                        continue
                                fi
                                found_url=$(echo $line | cut -d "," -f 1)
                                if ! [[ $found_url == "" ]]; then
                                        f=$(echo "$url$found_url/" | tr "/" "_")
                                        index=$(($index+1))
                                        list+=(["$index"]="$f")
                                        dir_list+=(["$index"]="$f")
                                fi
                        done < "$file_name"
                        index_del=0
                        for i in `seq 1 $index`; do
                                if [[ $current_url_to_delete_from_list == "${list[$i]}" ]]; then        
                                        unset list[$i]
                                        break
                                fi
                        done
                done
        done
        echo "All Found"
        for t in ${dir_list[@]}; do
                echo $t | tr "_" "/"
        done
        if [[ -z "$3" ]]; then
                echo "WORDLIST FOR FILE IS NOT SET"
                exit 1
        fi
        file_wordlist=$3
        for url in ${dir_list[@]}; do
                url_input=$(echo $url | tr "_" "/")
                file_name="$url""files"
                ffuf -u "$serv""://$host""$url_input""FUZZ" -w $file_wordlist -t 40 -o "$file_name" -of csv
        done
done
