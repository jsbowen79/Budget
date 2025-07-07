import React, { useState } from 'react';
import './App.css';

function App() {
  const [incomeItems, setIncomeItems] = useState([]);
  const [expenseItems, setExpenseItems] = useState([]);
  const [incomeInput, setIncomeInput] = useState({ desc: '', amount: '' });
  const [expenseInput, setExpenseInput] = useState({ desc: '', amount: '' });

  const addIncome = () => {
    const amount = parseFloat(incomeInput.amount);
    if (!incomeInput.desc || isNaN(amount) || amount <= 0) return;
    setIncomeItems([...incomeItems, { ...incomeInput, amount }]);
    setIncomeInput({ desc: '', amount: '' });
  };

  const addExpense = () => {
    const amount = parseFloat(expenseInput.amount);
    if (!expenseInput.desc || isNaN(amount) || amount <= 0) return;
    setExpenseItems([...expenseItems, { ...expenseInput, amount }]);
    setExpenseInput({ desc: '', amount: '' });
  };

  const totalIncome = incomeItems.reduce((sum, item) => sum + item.amount, 0);
  const totalExpenses = expenseItems.reduce((sum, item) => sum + item.amount, 0);
  const netBalance = totalIncome - totalExpenses;

  return (
    <div className="App">
      <h1>React Budget Planner</h1>

      <div className="section">
        <h2>Add Income</h2>
        <input
          type="text"
          placeholder="Income Source"
          value={incomeInput.desc}
          onChange={e => setIncomeInput({ ...incomeInput, desc: e.target.value })}
        />
        <input
          type="number"
          placeholder="Amount"
          value={incomeInput.amount}
          onChange={e => setIncomeInput({ ...incomeInput, amount: e.target.value })}
        />
        <button onClick={addIncome}>Add Income</button>

        <table>
          <thead>
            <tr><th>Source</th><th>Amount</th></tr>
          </thead>
          <tbody>
            {incomeItems.map((item, index) => (
              <tr key={index}><td>{item.desc}</td><td>${item.amount.toFixed(2)}</td></tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="section">
        <h2>Add Expense</h2>
        <input
          type="text"
          placeholder="Expense Name"
          value={expenseInput.desc}
          onChange={e => setExpenseInput({ ...expenseInput, desc: e.target.value })}
        />
        <input
          type="number"
          placeholder="Amount"
          value={expenseInput.amount}
          onChange={e => setExpenseInput({ ...expenseInput, amount: e.target.value })}
        />
        <button onClick={addExpense}>Add Expense</button>

        <table>
          <thead>
            <tr><th>Bill</th><th>Amount</th></tr>
          </thead>
          <tbody>
            {expenseItems.map((item, index) => (
              <tr key={index}><td>{item.desc}</td><td>${item.amount.toFixed(2)}</td></tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="summary">
        <p>Total Income: ${totalIncome.toFixed(2)}</p>
        <p>Total Expenses: ${totalExpenses.toFixed(2)}</p>
        <p>
          Net Balance: <span className={netBalance >= 0 ? 'positive' : 'negative'}>
            ${netBalance.toFixed(2)}
          </span>
        </p>
      </div>
    </div>
  );
}

export default App;
