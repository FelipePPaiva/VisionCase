import styles from './Login.module.css';
export function Login(){
 
    return(
        <div className={styles.conteiner}>
            <div className={styles.content}>
                <header className={styles.header}>
                    <h1>Login</h1>
                </header>
                <main>
                    <form className={styles.contentForm}>
                        <input type="text" placeholder="Usuário"/>
                        <input type="password" placeholder="Senha"/>
                        <div >
                            <div className={styles.option}>
                                <input type="checkbox" placeholder="Lembre-me"/>
                                <span>Lembre-me</span>
                            </div>
                            <a href="">Esqueceu a senha?</a>
                        </div>
                        <button type="submit">Login</button>
                    </form>
                </main>
            </div>
        </div>
    )
}