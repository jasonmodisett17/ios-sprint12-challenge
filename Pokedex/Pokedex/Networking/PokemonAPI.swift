//
//  PokemonAPI.swift
//  Pokedex
//
//  Created by Jason Modisett on 2/1/19.
//  Copyright © 2019 Jason Modisett. All rights reserved.
//

import UIKit

class PokemonAPI: NSObject {
    
    @objc(sharedController) static let shared =  PokemonAPI()
    
    override init() { self.pokemon = [] }
    
    @objc func fetchAllPokemon(completion: @escaping ([Pokemon]?, Error?) -> Void) {
        
        let allPokemonUrl = baseUrl.appendingPathComponent("pokemon")
        let query = URLQueryItem(name: "limit", value: "200")
        
        var components = URLComponents(url: allPokemonUrl, resolvingAgainstBaseURL: true)
        components?.queryItems = [query]
        
        let request = URLRequest(url: components?.url ?? allPokemonUrl)
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            
            if let error = error {
                NSLog("Error \(error)")
                return
            }
            
            guard let data = data else {
                NSLog("No data returned from data task")
                return
            }
            
            do {
                guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                    let pokemonDictionaries = dictionary["results"] as? [[String: Any]] else {
                        completion(nil, error)
                        return
                }
                self.pokemon = pokemonDictionaries.map { Pokemon(dictionary: $0)}
                completion(self.pokemon, nil)
            } catch {
                completion(nil, error)
                return
            }
            }.resume()
    }
    
    
    @objc func fillInDetails(for pokemon: Pokemon) {
        
        let url = URL(string: pokemon.pokemonUrl.absoluteString)!
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            
            if let error = error {
                NSLog("Error \(error)")
                return
            }
            
            guard let data = data else {
                NSLog("No data returned from data task")
                return
            }
            
            do {
                guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { return }
                var abilityNames: [String] = []
                
                guard let identifier = dictionary["id"] as? Int else { return }
                pokemon.identifier = String(identifier)
                
                
                if let abilities = dictionary["abilities"] as? [[String: Any]] {
                    for ability in abilities {
                        let innerAbility = ability["ability"] as! [String: Any]
                        let name = innerAbility["name"] as! String
                        abilityNames.append(name)
                    }
                    pokemon.abilities = abilityNames
                }
                
                if let sprites = dictionary["sprites"] as? [String: Any] {
                    let spriteStringUrl: String = sprites["front_default"] as! String
                    let url = URL(string: spriteStringUrl)!
                    self.getImage(url: url, completion: { (image, _) in
                        pokemon.image = image!
                    })
                }
                
            } catch {
                return
            }
            
        }.resume()
    }
    
    func getImage(url: URL, completion: @escaping (UIImage?, Error?) -> Void) {
        
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            
            if let error = error {
                NSLog("Error \(error)")
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                NSLog("Error returning image")
                completion(nil, NSError())
                return
            }
            
            let image = UIImage(data: data)
            completion(image, error)
            
            }.resume()
    }
    
    let baseUrl = URL(string: "https://pokeapi.co/api/v2/")!
    private(set) var pokemon: [Pokemon]
}
