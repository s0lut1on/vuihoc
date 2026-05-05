use anyhow::Result;
use minijinja::Environment;
use std::collections::HashMap;

pub fn render_stem(template: &str, params: &HashMap<String, f64>) -> Result<String> {
    let mut env = Environment::new();
    env.add_template("stem", template)?;
    let tmpl = env.get_template("stem")?;
    let ctx = minijinja::Value::from_serialize(params);
    Ok(tmpl.render(ctx)?)
}

pub fn eval_solution(expr: &str, params: &HashMap<String, f64>) -> Result<f64> {
    let mut expression = expr.to_string();
    for (k, v) in params {
        expression = expression.replace(k.as_str(), &v.to_string());
    }
    Ok(meval::eval_str(&expression)?)
}
