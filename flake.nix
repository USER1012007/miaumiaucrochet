{
  description = "frontend application";
  
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  
  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSystem = f: nixpkgs.lib.genAttrs systems (system:
        f {
          pkgs = import nixpkgs { inherit system; };
        }
      );
    in
    {
      devShells = forEachSystem ({ pkgs }:
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              nodejs
              nodePackages.npm
              nodePackages.pnpm
              nodePackages.yarn
            ];
            
            shellHook = ''
              echo "React development environment"
              echo "Node version: $(node --version)"
              echo "npm version: $(npm --version)"
              echo ""
              echo "Comandos útiles:"
              echo "  npm install       - Instalar dependencias"
              echo "  npm run dev       - Iniciar servidor de desarrollo"
              echo "  npm run build     - Compilar para producción"
              echo "  npm run preview   - Vista previa de producción"
            '';
          };
        }
      );
      
      packages = forEachSystem ({ pkgs }:
        {
          default = pkgs.buildNpmPackage {
            pname = "react-frontend";
            version = "1.0";
            src = ./.;
            
            npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
            # Ejecuta 'nix build' una vez para obtener el hash correcto
            # y reemplaza el valor de arriba con el hash proporcionado
            
            buildPhase = ''
              npm run build
            '';
            
            installPhase = ''
              mkdir -p $out/share
              cp -r dist $out/share/www
              
              # Crear script para servir la aplicación
              mkdir -p $out/bin
              cat > $out/bin/start-server << 'EOF'
              #!/bin/sh
              ${pkgs.python3}/bin/python -m http.server 5173 -d $out/share/www
              EOF
              chmod +x $out/bin/start-server
            '';
          };
        }
      );
      
      apps = forEachSystem ({ pkgs }:
        {
          default = {
            type = "app";
            program = "${self.packages.${pkgs.system}.default}/bin/start-server";
          };
          
          dev = {
            type = "app";
            program = "${pkgs.writeShellScriptBin "dev-server" ''
              set -e
              ${pkgs.nodejs}/bin/npm run dev
            ''}/bin/dev-server";
          };
        }
      );
    };
}
